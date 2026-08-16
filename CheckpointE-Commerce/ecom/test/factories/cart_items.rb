FactoryBot.define do
  factory :cart_item do
    association :cart
    association :item
    quantity { 2 }
    unit_price { 1500.00 }
    total_price { 3000.00 }
  end
end
