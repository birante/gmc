class VendorVerification < ApplicationRecord
  belongs_to :vendor

  CHANNELS = %w[email sms].freeze

  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :code, presence: true
  validates :expires_at, presence: true
  validates :status, inclusion: { in: [ true, false ] }

  scope :active, -> { where("expires_at > ? AND status = ? AND used_at IS NULL", Time.current, false) }
  scope :by_channel, ->(c) { where(channel: c.to_s) }

  def used?
    status == true || used_at.present?
  end

  def mark_used!
    update!(status: true, used_at: Time.current)
  end

  def email?
    channel == "email"
  end

  def sms?
    channel == "sms"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "vendor_id", "channel", "code", "expires_at", "status", "used_at", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "vendor" ]
  end
end
