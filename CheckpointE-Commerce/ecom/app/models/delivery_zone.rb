class DeliveryZone < ApplicationRecord
  has_many :zone_slots, dependent: :destroy
  has_many :delivery_slots, through: :zone_slots
  has_many :orders
  has_many :addresses
  has_many :delivery_prices, dependent: :destroy
  has_many :delivery_categories, through: :delivery_prices

  validates :name, presence: true, uniqueness: true
  validates :base_fee, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_active: true) }

  # Méthode pour trouver une zone par coordonnées (logique simplifiée)
  def self.find_by_coordinates(latitude, longitude)
    # TODO: Implémenter la logique géographique
    # Pour l'instant, retourne la première zone active
    active.first
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "description", "base_fee", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "zone_slots", "delivery_slots", "orders", "addresses", "delivery_prices", "delivery_categories" ]
  end
end
