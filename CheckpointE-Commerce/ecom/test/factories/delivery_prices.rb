FactoryBot.define do
  factory :delivery_price do
    delivery_zone { nil }
    delivery_category { nil }
    price { "9.99" }
  end
end
