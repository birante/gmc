class Rule < ApplicationRecord
  has_many :plan_rules, dependent: :destroy
  has_many :plans, through: :plan_rules
  has_many :shop_rules, dependent: :destroy
  has_many :shops, through: :shop_rules

  validates :code, presence: true, uniqueness: true
  validates :rule_type, presence: true, inclusion: { in: %w[integer boolean string jsonb] }

  scope :active, -> { where(is_active: true) }

  def self.ransackable_attributes(auth_object = nil)
    [ "code", "created_at", "default_value", "description", "id", "id_value", "is_active", "rule_type", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "plan_rules", "plans", "shop_rules", "shops" ]
  end
end
