FactoryBot.define do
  factory :plan do
    sequence(:code) { |n| "PLAN#{n}" }
    sequence(:name) { |n| "Plan #{n}" }
    description { "Test plan description" }
    is_custom { false }
    is_active { true }
  end
end
