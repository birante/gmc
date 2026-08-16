class Shop < ApplicationRecord
  include PgSearch::Model
  extend FriendlyId
  include PublicLink

  pg_search_scope :search_fuzzy,
    against: [ :name, :slug, :description ],
    using: {
      tsearch: { prefix: true, any_word: true },
      trigram: { threshold: 0.3 }
    }

  friendly_id :name, use: :slugged

  # Active Storage attachments
  has_one_attached :logo
  has_one_attached :banner_image # Gardé pour compatibilité, mais utiliser shop_banners maintenant

  has_many :shop_banners, dependent: :destroy
  has_one :shop_page_header, dependent: :destroy # Legacy, préférer shop_page_header_slides
  has_many :shop_page_header_slides, dependent: :destroy
  has_many :shop_page_sections, dependent: :destroy

  belongs_to :vendor
  belongs_to :currency, optional: true
  has_one :legal_info, class_name: "ShopLegalInfo", dependent: :destroy
  has_many :social_links, class_name: "ShopSocialLink", dependent: :destroy
  has_many :contacts, class_name: "ShopContact", dependent: :destroy
  has_many :shop_sectors, class_name: "ShopSector", dependent: :destroy
  has_many :sectors, through: :shop_sectors
  has_many :shop_payment_methods, class_name: "ShopPaymentMethod", dependent: :destroy
  has_many :payment_methods, through: :shop_payment_methods
  has_many :items, dependent: :destroy, counter_cache: :items_count
  has_many :available_items, -> { available_for_sale }, class_name: "Item"
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, -> { distinct }, through: :order_items
  has_many :employee_shops, dependent: :destroy
  has_many :employees, through: :employee_shops
  has_many :ahoy_events, class_name: "Ahoy::Event", dependent: :nullify

  has_many :shop_transactions, dependent: :destroy
  has_many :payouts, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :subscription_payments, dependent: :destroy
  has_many :plans, through: :subscriptions
  has_many :shop_rules, dependent: :destroy
  has_many :rules, through: :shop_rules
  has_many :shop_add_ons, dependent: :destroy
  has_many :add_ons, through: :shop_add_ons
  has_many :shop_colors, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :legal_info, allow_destroy: true
  accepts_nested_attributes_for :contacts, allow_destroy: true
  accepts_nested_attributes_for :social_links, allow_destroy: true
  accepts_nested_attributes_for :shop_payment_methods, allow_destroy: true
  accepts_nested_attributes_for :shop_banners, allow_destroy: true

  STATUSES = %w[pending active suspended deactivate].freeze
  SHOP_TYPES = %w[local official].freeze

  enum :status, STATUSES.index_by(&:to_sym), default: :pending
  enum :shop_type, { local: "local", official: "official" }, default: :local

  validates :name, presence: true, uniqueness: true
  validates :status, presence: true
  validates :address, presence: true

  before_validation :set_default_status
  before_create :generate_shop_code
  after_create :set_default_social_links
  after_create :set_default_contacts
  after_create :seed_default_shop_colors

  # Callback pour initialiser available_items_count après création
  after_create :initialize_available_items_count


  # Pour obtenir l'historique des gains (ventes livrées)
  def sales_history
    shop_transactions.where(transaction_type: "credit").order(created_at: :desc)
  end

  # Pour obtenir l'historique des reversements reçus
  def payout_history
    payouts.order(created_at: :desc)
  end

  # Calcule le montant total qui n'a pas encore été mis dans un Payout
  def pending_payout_amount
    shop_transactions.where(payout_id: nil, transaction_type: "credit").sum(:amount)
  end

  private

  def generate_shop_code
    loop do
      code = "SHOP" + SecureRandom.hex(3).upcase

      unless Shop.exists?(code: code)
      self.code = code
            Rails.logger.info("📝 [Shop] Code généré pour nouvelle boutique - code: #{code}, nom: #{name}")
        break
      end
    end
  end

  def set_default_status
    self.status = "pending" if self.status.blank?
    # shop_type a maintenant une valeur par défaut dans la base de données
    # mais on s'assure quand même qu'il est défini
    self.shop_type = "local" if self.shop_type.blank?
  end

  def set_default_social_links
    # Recharger pour s'assurer qu'on vérifie les associations sauvegardées
    reload if persisted?
    return if social_links.exists? # Skip if links already exist

    Rails.logger.info("🔗 [Shop] Création des liens sociaux par défaut - shop_id: #{id}")
    SocialPlatform.where(is_active: true).order(:position).each do |platform|
      begin
        social_links.create!(social_platform: platform, url: "")
      rescue => e
        Rails.logger.error "❌ [Shop] Failed to create social link for platform #{platform.id}: #{e.message}"
        # Continue avec les autres plateformes même si une échoue
      end
    end
    Rails.logger.info("🔗 [Shop] #{social_links.count} liens sociaux créés - shop_id: #{id}")
  end

  def set_default_contacts
    return if contacts.any? # Skip if contacts already exist
    Rails.logger.info("📞 [Shop] Création du contact par défaut - shop_id: #{id}")
    contacts.create!(country_code: "221", phone_number: "", is_whatsapp: false)
  end

  def initialize_available_items_count
    update_column(:available_items_count, items.available_for_sale.count)
  end

  # Pré-remplit la palette avec une sélection de couleurs universelles pour
  # que le vendeur ait quelque chose à choisir dès sa première variante.
  def seed_default_shop_colors
    return if shop_colors.exists?

    ShopColor::DEFAULT_STARTER_PALETTE.each_with_index do |attrs, index|
      shop_colors.create!(attrs.merge(position: index + 1))
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("⚠️ [Shop] Impossible de seeder la couleur #{attrs[:name]} pour shop #{id}: #{e.message}")
    end
    Rails.logger.info("🎨 [Shop] Palette par défaut créée (#{ShopColor::DEFAULT_STARTER_PALETTE.size} couleurs) - shop_id: #{id}")
  end

  public

  # Backfill : ajoute la palette de démarrage à toutes les boutiques qui
  # n'ont encore aucune couleur enregistrée. Utile après le déploiement
  # de la feature « Palette boutique » sur une base existante.
  def self.backfill_default_shop_colors!
    total_seeded = 0
    where.missing(:shop_colors).find_each do |shop|
      shop.send(:seed_default_shop_colors)
      total_seeded += 1
    end
    Rails.logger.info("🎨 [Shop] Backfill palette terminé - #{total_seeded} boutique(s) traitée(s)")
    total_seeded
  end

  # Recalcule le compteur cache à partir du vrai nombre de produits disponibles.
  # Utile quand le compteur a dérivé (imports, update_columns, suppressions
  # massives qui n'ont pas joué les callbacks Item).
  def recompute_available_items_count!
    update_column(:available_items_count, items.available_for_sale.count)
  end

  # Recolle le compteur cache pour toutes les boutiques en une passe SQL groupée.
  def self.recompute_all_available_items_counts!
    real_counts = Item.available_for_sale.group(:shop_id).count

    transaction do
      find_each do |shop|
        real = real_counts[shop.id] || 0
        next if shop.available_items_count == real
        shop.update_column(:available_items_count, real)
      end
    end
  end

  private

  # Scopes pour les statuts et types de boutiques
  scope :active, -> { where(status: :active) }
  scope :local_shops, -> { where(shop_type: :local) }
  scope :official_shops, -> { where(shop_type: :official) }

  def self.ransackable_attributes(auth_object = nil)
    [ "code", "created_at", "id", "name", "slug", "status", "updated_at", "vendor_id", "address", "description", "primary_color", "secondary_color", "shop_type" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "vendor", "legal_info", "social_links", "contacts", "sectors", "items" ]
  end

  public

  # ==========================================
  # PUBLIC METHODS
  # ==========================================

  # Vérifie si la boutique est vérifiée (active avec informations légales)
  def verified?
    active? && legal_info&.persisted?
  end

  # Méthodes helper pour le type de boutique
  def local?
    shop_type == "local"
  end

  def official?
    shop_type == "official"
  end

  # Retourne l'abonnement actif actuel
  def current_subscription
    subscriptions.active.order(created_at: :desc).first
  end

  # Retourne les capacités de la boutique (facade métier)
  # @return [Shops::Capabilities]
  def capabilities
    @capabilities ||= Shops::Capabilities.new(self)
  end

  # Note moyenne agrégée à partir des avis approuvés de tous les produits de la boutique
  def average_rating
    @average_rating ||= Review.approved.joins(:item).where(items: { shop_id: id }).average(:rating)&.round(2)
  end

  # Nombre total d'avis approuvés sur les produits de la boutique
  def reviews_count
    @reviews_count ||= Review.approved.joins(:item).where(items: { shop_id: id }).count
  end

  # ==========================================
  # ANALYTICS METHODS
  # ==========================================

  def increment_view_count
    increment!(:views_count)
  end

  # Statistiques de la boutique
  def analytics_summary(period: 7.days)
    start_time = period.ago

    {
      total_views: views_count,
      recent_views: ahoy_events
        .where(name: "shop_viewed")
        .where("time >= ?", start_time)
        .count,
      unique_visitors: ahoy_events
        .where(name: "shop_viewed")
        .where("time >= ?", start_time)
        .distinct
        .count(:visit_id),
      top_items: items
        .includes(:product_sub_category)
        .order(views_count: :desc)
        .limit(10),
      conversion_rate: calculate_conversion_rate(start_time)
    }
  end

  # Statistiques par jour
  def daily_views(start_date:, end_date:)
    ahoy_events
      .where(name: "shop_viewed")
      .where(time: start_date.beginning_of_day..end_date.end_of_day)
      .group_by_day(:time, time_zone: "UTC")
      .count
  end

  private

  def calculate_conversion_rate(start_time)
    views = ahoy_events.where(name: "shop_viewed").where("time >= ?", start_time).count
    return 0 if views.zero?

    orders = ahoy_events.where(name: "order_completed").where("time >= ?", start_time).count
    (orders.to_f / views * 100).round(2)
  end

  def public_url
    Rails.application.routes.url_helpers.client_shop_url(
      slug: friendly_id,
      host: Rails.configuration.action_controller.asset_host || Rails.application.config.app_host || "localhost:3000"
    )
  rescue
    nil
  end
end
