FactoryBot.define do
  factory :product_attribute_value do
    product_attribute { nil }
    value { "MyString" }
    is_active { false }
  end
end
