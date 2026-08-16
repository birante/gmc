FactoryBot.define do
  factory :item do
    association :shop
    association :product_sub_category
    association :delivery_category
    # Use the fixture currency to avoid duplicate XOF entries
    currency { Currency.find_by(code: "XOF") || create(:currency, :xof) }

    sequence(:name) { |n| "Article Test #{n}" }
    # Price and stock_quantity are stored in ItemVariant, not Item
    default_price { 1500.00 }
    default_stock_quantity { 50 }
    validation_status { "approved" }
    description { "Description de l'article de test" }
  end
end
