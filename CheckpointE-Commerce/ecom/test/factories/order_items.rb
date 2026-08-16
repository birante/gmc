FactoryBot.define do
  factory :order_item do
    order { nil }
    item { nil }
    shop { nil }
    unit_price { "9.99" }
    quantity { 1 }
    total_price { "9.99" }
    delivery_status { "pending_shipment" }
  end
end
