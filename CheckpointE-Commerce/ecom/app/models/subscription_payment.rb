class SubscriptionPayment < ApplicationRecord
  belongs_to :shop
  belongs_to :plan
  belongs_to :payment_method

  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :withdraw_mode, presence: true

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  scope :completed, -> { where(status: "completed") }
  scope :pending, -> { where(status: "pending") }
  scope :failed, -> { where(status: "failed") }

  before_create :generate_transaction_id
  after_create :log_payment_creation
  after_update :log_payment_status_change, if: :saved_change_to_status?

  def self.ransackable_attributes(auth_object = nil)
    [ "amount", "created_at", "id", "paid_at", "paydunya_invoice_url", "paydunya_token", "payment_method_id", "payment_type", "plan_id", "shop_id", "status", "transaction_id", "withdraw_mode", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shop", "plan", "payment_method" ]
  end

  def completed?
    status == "completed" && paid_at.present?
  end

  def pending?
    status == "pending"
  end

  def failed?
    status == "failed"
  end

  private

  def generate_transaction_id
    self.transaction_id ||= "SUB-TXN-#{Time.current.to_i}-#{SecureRandom.hex(4).upcase}"
  end

  def log_payment_creation
    Rails.logger.info("💳 [SubscriptionPayment] Paiement d'abonnement créé - payment_id: #{id}, shop_id: #{shop_id}, plan: #{plan.code}, montant: #{amount} FCFA, mode: #{withdraw_mode}")
  end

  def log_payment_status_change
    old_status = status_before_last_save
    Rails.logger.info("✏️ [SubscriptionPayment] Changement statut - payment_id: #{id}, ancien_statut: #{old_status}, nouveau_statut: #{status}")
  end
end
