FactoryBot.define do
  factory :plan_rule do
    plan { nil }
    rule { nil }
    value { "" }
    is_active { false }
  end
end
