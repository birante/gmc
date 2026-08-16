class PaymentMethod < ApplicationRecord
  has_many :subscription_payments, dependent: :destroy

  scope :active, -> { where(is_active: true) }

  validates :name, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "code", "name", "description", "is_active", "display_order", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
