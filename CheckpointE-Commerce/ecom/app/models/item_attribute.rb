class ItemAttribute < ApplicationRecord
  belongs_to :item
  has_many :attribute_values, dependent: :destroy
  accepts_nested_attributes_for :attribute_values, allow_destroy: true

  validates :name, presence: true, uniqueness: { scope: :item_id }
  validates :position, presence: true, numericality: { only_integer: true }

  scope :ordered, -> { order(:position) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "item_id", "name", "position", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "attribute_values", "item" ]
  end
end
