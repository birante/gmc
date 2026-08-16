class DeliveryPrice < ApplicationRecord
  belongs_to :delivery_zone
  belongs_to :delivery_category

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :delivery_zone_id, uniqueness: { scope: :delivery_category_id,
                                              message: "a déjà un prix pour cette catégorie" }

  # Retourne le prix pour une zone et une catégorie données
  def self.find_price(zone_id, category_id)
    find_by(delivery_zone_id: zone_id, delivery_category_id: category_id)&.price || 0.0
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "delivery_zone_id", "delivery_category_id", "price", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "delivery_zone", "delivery_category" ]
  end
end
