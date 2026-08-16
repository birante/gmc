FactoryBot.define do
  factory :shop_rule do
    shop { nil }
    rule { nil }
    value { "" }
    is_active { false }
  end
end
