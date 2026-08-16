class PlanRule < ApplicationRecord
  belongs_to :plan
  belongs_to :rule

  validates :plan_id, uniqueness: { scope: :rule_id }
  validates :is_active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(is_active: true) }

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "id_value", "is_active", "plan_id", "rule_id", "updated_at", "value" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "plan", "rule" ]
  end
end
