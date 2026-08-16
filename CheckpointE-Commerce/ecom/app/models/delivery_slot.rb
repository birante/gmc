class DeliverySlot < ApplicationRecord
  has_many :zone_slots, dependent: :destroy
  has_many :delivery_zones, through: :zone_slots
  has_many :orders

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  scope :active, -> { where(is_active: true) }

  def time_range
    "#{start_time.strftime('%H:%M')} - #{end_time.strftime('%H:%M')}"
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "doit être après l'heure de début")
    end
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "start_time", "end_time", "is_active", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "zone_slots", "delivery_zones", "orders" ]
  end
end
