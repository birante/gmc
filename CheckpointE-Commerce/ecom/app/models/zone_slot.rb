class ZoneSlot < ApplicationRecord
  belongs_to :delivery_zone
  belongs_to :delivery_slot

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "delivery_zone_id", "delivery_slot_id", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "delivery_zone", "delivery_slot" ]
  end
end
