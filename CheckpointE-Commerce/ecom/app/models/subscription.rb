class Subscription < ApplicationRecord
  belongs_to :shop
  belongs_to :plan

  validates :status, presence: true, inclusion: { in: %w[active expired cancelled] }

  scope :active, -> { where(status: "active").where("ends_at IS NULL OR ends_at > ?", Time.current) }
  scope :expired, -> { where("status = ? OR (status = ? AND ends_at < ?)", "expired", "active", Time.current) }
  scope :cancelled, -> { where(status: "cancelled") }

  def active?
    status == "active" && (ends_at.nil? || ends_at > Time.current)
  end

  def expired?
    status == "expired" || (status == "active" && ends_at.present? && ends_at < Time.current)
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "ends_at", "id", "id_value", "plan_id", "shop_id", "started_at", "status", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop", "plan" ]
  end
end
