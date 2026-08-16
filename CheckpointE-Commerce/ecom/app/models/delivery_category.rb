class DeliveryCategory < ApplicationRecord
  has_many :items, dependent: :restrict_with_error
  has_many :delivery_prices, dependent: :destroy
  has_many :delivery_zones, through: :delivery_prices

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z_]+\z/, message: "doit être en minuscules avec underscores uniquement" }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:display_order) }

  # Catégories prédéfinies - Codes
  STANDARD = "standard"
  CARGO = "cargo"

  # Retourne la catégorie la plus grande parmi un ensemble
  def self.largest_among(categories)
    categories.max_by(&:display_order)
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "code", "description", "display_order", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "items", "delivery_prices", "delivery_zones" ]
  end
end
