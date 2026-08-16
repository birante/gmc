FactoryBot.define do
  factory :delivery_zone do
    sequence(:name) { |n| "Zone #{n}" }
    base_fee { 500.00 }
    min_delivery_time { 60 }
    max_delivery_time { 120 }
    is_active { true }
  end
end
