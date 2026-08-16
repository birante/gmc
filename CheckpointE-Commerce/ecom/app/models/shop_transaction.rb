class ShopTransaction < ApplicationRecord
  belongs_to :shop
  belongs_to :order, optional: true
  belongs_to :payout, optional: true
  belongs_to :currency, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_type, presence: true, inclusion: { in: %w[credit debit refund] }

  # Scope pour voir ce qui n'a pas encore été reversé à la boutique
  scope :unpaid, -> { where(payout_id: nil, transaction_type: "credit") }

  # Scope pour les crédits (ventes)
  scope :credits, -> { where(transaction_type: "credit") }

  # Scope pour les débits (reversements)
  scope :debits, -> { where(transaction_type: "debit") }

  def self.ransackable_attributes(auth_object = nil)
    [ "amount", "created_at", "currency_id", "description", "id", "metadata", "order_id", "payout_id", "shop_id", "transaction_type", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "currency", "order", "payout", "shop" ]
  end
end
