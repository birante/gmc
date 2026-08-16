
class Item < ApplicationRecord
  include PgSearch::Model
  extend FriendlyId
  include PublicLink

  pg_search_scope :search_fuzzy,
    against: [ :name, :slug, :description ],
    associated_against: {
      shop: [ :name ],
      product_sub_category: [ :name ]
    },
    using: {
      tsearch: { prefix: true, any_word: true },
      trigram: { threshold: 0.3 }
    }

  attribute :cash_on_delivery_disabled, :boolean, default: true

  friendly_id :name, use: :slugged

  # Active Storage attachments pour les images produits
  has_one_attached :main_image
  has_many_attached :images

  belongs_to :shop
  belongs_to :product_sub_category, optional: true
  belongs_to :currency
  belongs_to :delivery_category, optional: true

  has_many :variants, dependent: :destroy, class_name: "ItemVariant", counter_cache: :variants_count
  accepts_nested_attributes_for :variants, allow_destroy: true

  has_many :item_attributes, dependent: :destroy, class_name: "ItemAttribute", foreign_key: "item_id"
  accepts_nested_attributes_for :item_attributes, allow_destroy: true

  has_many :order_items, dependent: :restrict_with_error
  has_many :reviews, dependent: :destroy
  has_many :ahoy_events, class_name: "Ahoy::Event", dependent: :nullify

  VALIDATION_STATUSES = %w[pending approved rejected].freeze
  AI_ENRICHMENT_STATUSES = %w[pending processing completed failed].freeze

  # Codes ISO des pays supportés
  ORIGIN_COUNTRIES = {
    "SN" => "Sénégal",
    "GM" => "Gambie"
  }.freeze

  # Codes alignés sur les `radio_button_tag :payment_method` du checkout client
  CHECKOUT_PAYMENT_CODES = %w[
    cash_on_delivery wave-senegal orange-money-senegal free-money-senegal expresso-senegal
  ].freeze

  # Attributs virtuels pour créer la variante par défaut
  attr_accessor :default_price, :default_stock_quantity

  validates :name, presence: true
  validates :validation_status, inclusion: { in: VALIDATION_STATUSES }
  validates :origin_country, inclusion: { in: ORIGIN_COUNTRIES.keys }, allow_nil: true

  def public_url
    Rails.application.routes.url_helpers.client_produit_url(
      id: friendly_id,
      host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
    )
  rescue
    nil
  end
  validates :ai_enrichment_status, inclusion: { in: AI_ENRICHMENT_STATUSES }, allow_nil: true
  validates :delivery_category, presence: { message: "doit être sélectionnée" }, if: :approved?
  validate :has_at_least_one_variant
  validate :validate_allowed_payment_codes_field

  after_create :create_default_variant_if_needed
  after_save :set_origin_country_from_category, if: :saved_change_to_product_sub_category_id?
  after_save :update_shop_available_items_count, if: :saved_change_to_validation_status?
  after_destroy :decrement_shop_available_items_count_if_approved

  private

  def update_shop_available_items_count
    return unless shop

    old_status, new_status = saved_change_to_validation_status

    # Un produit est disponible côté client uniquement s'il est approuvé
    was_available = old_status == "approved"
    is_now_available = new_status == "approved"

    if !was_available && is_now_available
      # Item devient disponible
      shop.increment!(:available_items_count)
    elsif was_available && !is_now_available
      # Item n'est plus disponible
      shop.decrement!(:available_items_count) if shop.available_items_count > 0
    end
  end

  def decrement_shop_available_items_count_if_approved
    return unless shop && validation_status == "approved"

    shop.decrement!(:available_items_count) if shop.available_items_count > 0
  end

  public

  scope :available_for_sale, -> {
    where(validation_status: "approved")
  }

  scope :on_sale, -> {
    where(is_on_sale: true)
      .where("sale_start_date IS NULL OR sale_start_date <= ?", Time.current)
      .where("sale_end_date IS NULL OR sale_end_date >= ?", Time.current)
  }

  # Scopes pour l'origine des produits
  scope :made_in_senegal, -> { where(origin_country: "SN") }
  scope :made_in_gambie, -> { where(origin_country: "GM") }
  scope :made_in_africa, -> { where(origin_country: [ "SN", "GM" ]) }
  scope :by_origin_country, ->(country_code) { where(origin_country: country_code) }

  def allowed_payment_code_list
    allowed_payment_codes.to_s.split(/[\s,]+/).map(&:strip).compact_blank
  end

  def restricts_checkout_payment_codes?
    allowed_payment_code_list.any?
  end

  def validate_allowed_payment_codes_field
    return if allowed_payment_code_list.empty?

    unknown = allowed_payment_code_list - CHECKOUT_PAYMENT_CODES
    return if unknown.empty?

    errors.add(:allowed_payment_codes, "contient des codes inconnus : #{unknown.join(', ')}")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "currency_id", "delivery_category_id", "description", "id", "name", "position", "product_sub_category_id", "shop_id", "slug", "updated_at", "validation_status", "origin_country", "keywords", "cash_on_delivery_disabled" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "currency", "delivery_category", "product_sub_category", "shop" ]
  end

  def default_variant
    # Optimisation : si variants est déjà chargé en mémoire, chercher dedans
    # pour éviter une requête SQL supplémentaire
    if association(:variants).loaded?
      variants.find { |v| v.is_default } || variants.first
    else
      variants.default.first
    end
  end

  def approved?
    validation_status == "approved"
  end

  # ==========================================
  # AI ENRICHMENT METHODS
  # ==========================================

  def ai_enrichment_pending?
    ai_enrichment_status == "pending"
  end

  def ai_enrichment_processing?
    ai_enrichment_status == "processing"
  end

  def ai_enrichment_completed?
    ai_enrichment_status == "completed"
  end

  def ai_enrichment_failed?
    ai_enrichment_status == "failed"
  end

  def ai_enrichment_in_progress?
    ai_enrichment_processing?
  end

  def ai_enrichment_ready?
    ai_enrichment_completed?
  end

  def ai_field_generated?(field_name)
    ai_generated_fields&.dig(field_name.to_s) == true
  end

  def retry_ai_enrichment!
    return unless ai_enrichment_failed? || ai_enrichment_pending?

    update(ai_enrichment_status: "pending")
    ::ItemAIEnrichmentJob.perform_later(id)
  end

  # Génère les combinaisons de variantes basées sur les attributs
  def generate_variants!(default_price = nil, default_stock = nil)
    VariantGeneratorService.new(self).generate_variants!(default_price, default_stock)
  end

  # Régénère les variantes (supprime les anciennes et crée les nouvelles)
  def regenerate_variants!(default_price = nil, default_stock = nil)
    VariantGeneratorService.new(self).regenerate_variants!(default_price, default_stock)
  end

  # Obtient le nombre de combinaisons possibles
  def variant_combinations_count
    return 0 if item_attributes.empty?
    VariantGeneratorService.new(self).generate_combinations.length
  end

  # ==========================================
  # ANALYTICS METHODS
  # ==========================================

  def increment_view_count
    increment!(:views_count)
  end

  # Statistiques du produit
  def analytics_summary(period: 7.days)
    start_time = period.ago

    {
      total_views: views_count,
      recent_views: ahoy_events
        .where(name: "item_viewed")
        .where("time >= ?", start_time)
        .count,
      unique_visitors: ahoy_events
        .where(name: "item_viewed")
        .where("time >= ?", start_time)
        .distinct
        .count(:visit_id),
      add_to_cart_rate: calculate_add_to_cart_rate(start_time),
      total_added_to_cart: ahoy_events
        .where(name: "item_added_to_cart")
        .where("time >= ?", start_time)
        .count
    }
  end

  # Statistiques par jour
  def daily_views(start_date:, end_date:)
    ahoy_events
      .where(name: "item_viewed")
      .where(time: start_date.beginning_of_day..end_date.end_of_day)
      .group_by_day(:time, time_zone: "UTC")
      .count
  end

  def product_category
    product_sub_category&.product_category
  end

  # ==========================================
  # ORIGIN COUNTRY METHODS
  # ==========================================

  # Méthodes helper pour vérifier l'origine
  def made_in_senegal?
    origin_country == "SN"
  end

  def made_in_gambie?
    origin_country == "GM"
  end

  def made_in_africa?
    [ "SN", "GM" ].include?(origin_country)
  end

  # Retourne le nom du pays d'origine
  def origin_country_name
    ORIGIN_COUNTRIES[origin_country] if origin_country
  end

  # Définit automatiquement l'origine basée sur la catégorie
  def set_origin_country_from_category!
    category_name = product_sub_category&.product_category&.name

    case category_name
    when "Made in Sénégal / Made in Africa"
      # Si la catégorie est générique, on peut laisser l'utilisateur choisir
      # ou définir par défaut Sénégal si pas encore défini
      update(origin_country: "SN") if origin_country.blank?
    end
  end

  # ==========================================
  # IMAGE METHODS
  # ==========================================

  # Retourne l'image principale ou la première image de la galerie
  def display_image
    return main_image.blob if main_image.attached?

    return nil unless images.attached?

    first_image = images.first
    return first_image.blob if first_image.respond_to?(:blob)
    return first_image if first_image.present?

    nil
  end

  # Vérifie si le produit a au moins une image
  def has_image?
    main_image.attached? || images.attached?
  end

  def calculate_add_to_cart_rate(start_time)
    views = ahoy_events.where(name: "item_viewed").where("time >= ?", start_time).count
    return 0 if views.zero?

    adds = ahoy_events.where(name: "item_added_to_cart").where("time >= ?", start_time).count
    (adds.to_f / views * 100).round(2)
  end

  # ==========================================
  # PROMO/SALE METHODS
  # ==========================================

  # Vérifie si le produit est actuellement en promo (vérifie les dates)
  def on_sale?
    return false unless is_on_sale?

    # Vérifier les dates si elles sont définies
    if sale_start_date.present? && Time.current < sale_start_date
      return false
    end

    if sale_end_date.present? && Time.current > sale_end_date
      return false
    end

    true
  end

  # Retourne le prix actuel d'une variante (promo ou normal)
  def current_price(variant = nil)
    variant ||= default_variant || variants.first
    return variant.price unless variant

    variant.current_price
  end

  # Calcule le pourcentage de réduction pour une variante
  def discount_percentage(variant = nil)
    variant ||= default_variant || variants.first
    return 0 unless variant

    variant.discount_percentage
  end

  # Retourne le prix original d'une variante (avant promo)
  def original_price(variant = nil)
    variant ||= default_variant || variants.first
    variant&.price || 0
  end

  private

  def has_at_least_one_variant
    return if new_record?
    return if item_attributes.blank?
    # Verifier directement en base pour eviter les problemes de cache de collection
    errors.add(:base, "L'article doit avoir au moins une variante") unless ItemVariant.exists?(item_id: id)
  end

  def set_origin_country_from_category
    set_origin_country_from_category!
  end

  def create_default_variant_if_needed
    # Check if variants already exist (in database)
    # Use reload_association to ensure we're checking persisted records
    if variants.count > 0
      Rails.logger.info("[Item] Variantes deja presentes dans la DB, skip")
      return
    end

    unless default_price.present? && default_stock_quantity.present?
      Rails.logger.warn("[Item] default_price ou default_stock_quantity manquant, skip")
      return
    end

    Rails.logger.info("[Item] Creation variante par defaut - item_id: #{id}, prix: #{default_price}, stock: #{default_stock_quantity}")
    variant = variants.create!(
      price: default_price,
      stock_quantity: default_stock_quantity,
      is_default: true,
      sku: "#{id}-DEFAULT"
    )
    Rails.logger.info("[Item] Variante par defaut creee avec succes - variant_id: #{variant.id}")
  end
end
