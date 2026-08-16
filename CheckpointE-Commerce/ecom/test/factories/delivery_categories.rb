FactoryBot.define do
  factory :delivery_category do
    code { "test_category" }
    name { "MyString" }
    description { "MyText" }
    display_order { 1 }
  end
end
