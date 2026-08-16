class ProductAttributeValue < ApplicationRecord
  belongs_to :product_attribute

  validates :value, presence: true
  validates :value, uniqueness: { scope: :product_attribute_id }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:value) }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "product_attribute_id", "value", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "product_attribute" ]
  end
end
