class ProductAttribute < ApplicationRecord
  has_many :product_attribute_values, dependent: :destroy
  accepts_nested_attributes_for :product_attribute_values, allow_destroy: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:name) }

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "product_attribute_values" ]
  end
end
