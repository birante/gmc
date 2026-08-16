FactoryBot.define do
  factory :shop_payment_method do
    shop { nil }
    payment_method { nil }
    is_active { false }
  end
end
