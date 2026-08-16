FactoryBot.define do
  factory :item_variant do
    item { nil }
    size { "MyString" }
    color { "MyString" }
    sku { "MyString" }
    price { "9.99" }
    stock_quantity { 1 }
  end
end
