class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :item
  belongs_to :item_variant, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :item_variant_id, uniqueness: { scope: :cart_id }, if: :item_variant_id?
  validate :quantity_not_greater_than_stock

  before_save :calculate_prices
  after_create :log_cart_item_creation
  after_update :log_cart_item_update, if: :saved_change_to_quantity?

  def variant
    item_variant || item.variants.first
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "cart_id", "item_id", "item_variant_id", "quantity", "unit_price", "total_price", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "cart", "item", "item_variant" ]
  end

  private

  def calculate_prices
    # Utiliser le prix actuel (promo ou normal) au lieu du prix de base
    variant_price = if variant && variant.respond_to?(:current_price)
      variant.current_price
    elsif variant
      variant.price
    else
      0
    end
    self.unit_price = variant_price
    self.total_price = unit_price * quantity
  end

  def log_cart_item_creation
    Rails.logger.info("🛒 [CartItem] Ajout au panier - cart_item_id: #{id}, cart_id: #{cart_id}, item_id: #{item_id}, quantité: #{quantity}, prix_unitaire: #{unit_price}")
  end

  def log_cart_item_update
    Rails.logger.info("✏️ [CartItem] Mise à jour quantité - cart_item_id: #{id}, ancienne_quantité: #{quantity_before_last_save}, nouvelle_quantité: #{quantity}")
  end

  def quantity_not_greater_than_stock
    return unless variant

    if quantity && quantity > variant.stock_quantity
      errors.add(:quantity, "ne peut pas dépasser le stock disponible (#{variant.stock_quantity})")
    end
  end
end
