class AttributeValue < ApplicationRecord
  belongs_to :item_attribute
  belongs_to :shop_color, optional: true
  has_many :variant_attribute_values, dependent: :destroy
  has_many :variants, through: :variant_attribute_values, source: :item_variant

  validates :value, presence: true, uniqueness: { scope: :item_attribute_id }
  validates :position, presence: true, numericality: { only_integer: true }
  validates :hex_code, format: { with: ShopColor::HEX_FORMAT, message: "doit être au format #RRGGBB" }, allow_blank: true

  before_validation :sync_from_shop_color

  scope :ordered, -> { order(:position) }

  def color_swatch?
    hex_code.present?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "hex_code", "id", "item_attribute_id", "position", "shop_color_id", "updated_at", "value" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "item_attribute", "shop_color", "variant_attribute_values", "variants" ]
  end

  private

  def sync_from_shop_color
    return if shop_color.blank?
    self.value = shop_color.name if value.blank?
    self.hex_code = shop_color.hex_code if hex_code.blank?
  end
end
