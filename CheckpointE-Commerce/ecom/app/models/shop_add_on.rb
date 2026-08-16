class ShopAddOn < ApplicationRecord
  belongs_to :shop
  belongs_to :add_on

  validates :quantity, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where("starts_at IS NULL OR starts_at <= ?", Time.current).where("ends_at IS NULL OR ends_at >= ?", Time.current) }
  scope :expired, -> { where("ends_at IS NOT NULL AND ends_at < ?", Time.current) }
  scope :upcoming, -> { where("starts_at IS NOT NULL AND starts_at > ?", Time.current) }

  def active?
    (starts_at.nil? || starts_at <= Time.current) && (ends_at.nil? || ends_at >= Time.current)
  end

  def expired?
    ends_at.present? && ends_at < Time.current
  end

  def upcoming?
    starts_at.present? && starts_at > Time.current
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "add_on_id", "created_at", "ends_at", "id", "id_value", "quantity", "shop_id", "starts_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop", "add_on" ]
  end
end
