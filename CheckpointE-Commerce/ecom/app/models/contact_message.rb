class ContactMessage < ApplicationRecord
  STATUSES = %w[new in_progress handled archived].freeze

  validates :first_name, presence: true
  validates :message, presence: true, length: { maximum: 5_000 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :email_or_phone_present
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email", "first_name", "id", "last_name", "message",
      "phone", "status", "subject", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def email_or_phone_present
    return if email.present? || phone.present?

    errors.add(:base, :email_or_phone_required)
  end
end
