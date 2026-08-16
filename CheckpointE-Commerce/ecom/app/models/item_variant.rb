class ItemVariant < ApplicationRecord
  belongs_to :item
  has_many :variant_attribute_values, dependent: :destroy
  has_many :attribute_values, through: :variant_attribute_values

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: true, allow_blank: true

  before_validation :inherit_from_default_variant, if: :should_inherit?
  before_validation :normalize_prices_for_currency
  before_validation :generate_sku_if_blank
  validate :price_floor_for_currency
  after_create :log_variant_creation
  after_update :log_stock_change, if: :saved_change_to_stock_quantity?

  scope :default, -> { where(is_default: true) }
  scope :in_stock, -> { where("stock_quantity > 0") }

  def in_stock?
    stock_quantity > 0
  end

  def formatted_attributes
    attribute_values.joins(:item_attribute)
      .order("item_attributes.position")
      .pluck("item_attributes.name", "attribute_values.value")
      .map { |name, value| "#{name}: #{value}" }
      .join(" | ")
  end

  def display_name
    return "Variante par défaut" if is_default?

    attribute_labels = item.item_attributes.ordered.map do |attr|
      value = attribute_values.joins(:item_attribute)
        .where(item_attributes: { id: attr.id })
        .first&.value
      "#{attr.name}: #{value}" if value.present?
    end.compact

    attribute_labels.any? ? attribute_labels.join(" | ") : "Variante"
  end

  def attribute_display_hash
    hash = {}
    item.item_attributes.ordered.each do |attr|
      value = attribute_values.joins(:item_attribute)
        .where(item_attributes: { id: attr.id })
        .first&.value
      hash[attr.name] = value if value.present?
    end
    hash
  end

  # ==========================================
  # PROMO/SALE METHODS (PUBLIC)
  # ==========================================

  # Vérifie si cette variante est en promo
  def on_sale?
    return false unless item&.is_on_sale?
    return false unless item.on_sale? # Vérifie les dates globales

    # Si un prix promo est défini spécifiquement pour ce variant
    return true if sale_price.present?

    # Sinon, vérifier si l'item a un pourcentage de réduction global
    item.sale_discount_percent.present? && item.sale_discount_percent > 0
  end

  # Retourne le prix actuel (promo ou normal)
  def current_price
    return price unless on_sale?

    # Priorité au prix promo spécifique du variant
    if sale_price.present?
      return sale_price
    end

    # Sinon, calculer avec le pourcentage global de l'item
    if item.sale_discount_percent.present? && item.sale_discount_percent > 0
      discount = price * (item.sale_discount_percent / 100.0)
      return (price - discount).round(2)
    end

    price
  end

  # Retourne le prix original (avant promo)
  def original_price
    price
  end

  # Calcule le pourcentage de réduction pour ce variant
  def discount_percentage
    return 0 unless on_sale?

    if sale_price.present?
      discount = price - sale_price
      return 0 if price.zero?
      return ((discount / price) * 100).round
    end

    # Utiliser le pourcentage global de l'item
    item.sale_discount_percent&.round || 0
  end

  private

  def normalize_prices_for_currency
    return unless item&.currency&.code == "XOF"

    self.price = price.to_d.round if price.present?
    self.sale_price = sale_price.to_d.round if sale_price.present?
  end

  def should_inherit?
    return false if is_default?
    return false unless new_record?
    # Hériter si le prix ou le stock sont nil (pas seulement blank)
    price.nil? || stock_quantity.nil?
  end

  def price_floor_for_currency
    return if price.blank?

    if item&.currency&.code == "XOF"
      errors.add(:price, "doit être au minimum 1 FCFA") if price.to_d < 1
      errors.add(:sale_price, "doit être au minimum 1 FCFA") if sale_price.present? && sale_price.to_d < 1
    else
      errors.add(:price, "doit être supérieur à 0") if price.to_d <= 0
      errors.add(:sale_price, "doit être supérieur à 0") if sale_price.present? && sale_price.to_d <= 0
    end
  end

  def inherit_from_default_variant
    default_variant = item&.variants&.default&.first
    return unless default_variant

    # Utiliser nil? au lieu de ||= pour permettre l'écrasement de 0
    self.price = default_variant.price if price.nil?
    self.stock_quantity = default_variant.stock_quantity if stock_quantity.nil?
  end

  def generate_sku_if_blank
    return if sku.present?
    # Ne générer que pour les variantes par défaut
    # Les variantes non-par-défaut auront leur SKU généré par le service
    return unless is_default?

    self.sku = "#{item&.id || 'NEW'}-DEFAULT"
  end

  def log_variant_creation
    Rails.logger.info("[ItemVariant] Variante creee - variant_id: #{id}, item_id: #{item_id}, sku: #{sku}, prix: #{price}, stock: #{stock_quantity}")
  end

  def log_stock_change
    Rails.logger.info("[ItemVariant] Changement de stock - variant_id: #{id}, ancien_stock: #{stock_quantity_before_last_save}, nouveau_stock: #{stock_quantity}")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "item_id", "sku", "price", "stock_quantity", "is_default", "sale_price", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "item", "variant_attribute_values", "attribute_values" ]
  end
end
