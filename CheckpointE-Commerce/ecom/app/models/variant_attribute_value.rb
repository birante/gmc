class VariantAttributeValue < ApplicationRecord
  belongs_to :item_variant
  belongs_to :attribute_value

  validates :item_variant_id, uniqueness: { scope: :attribute_value_id }

  delegate :item_attribute, to: :attribute_value

  def self.ransackable_attributes(auth_object = nil)
    [ "attribute_value_id", "created_at", "id", "item_variant_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "attribute_value", "item_variant" ]
  end
end
