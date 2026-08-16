class Payout < ApplicationRecord
  belongs_to :shop
  belongs_to :currency, optional: true
  has_many :shop_transactions

  enum :status, {
    pending: "pending",
    processing: "processing",
    paid: "paid",
    failed: "failed"
  }, default: :pending

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0.01 }
  validates :payout_month, presence: true, inclusion: { in: 1..12 }
  validates :payout_year, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "amount", "created_at", "currency_id", "id", "paid_at", "payout_month", "payout_year", "reference_number", "shop_id", "status", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "currency", "shop", "shop_transactions" ]
  end
end
