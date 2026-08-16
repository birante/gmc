class NewsletterSubscriber < ApplicationRecord
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Callbacks
  before_save :downcase_email
  after_create :log_subscription

  # Scopes
  scope :subscribed, -> { where(subscribed: true) }
  scope :unsubscribed, -> { where(subscribed: false) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email", "id", "subscribed", "updated_at" ]
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end

  def log_subscription
    Rails.logger.info("📧 [NewsletterSubscriber] Nouvelle inscription: #{email}")
  end
end
