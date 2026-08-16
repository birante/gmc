FactoryBot.define do
  factory :review do
    user { nil }
    item { nil }
    order_item { nil }
    rating { 1 }
    comment { "MyText" }
    status { "MyString" }
    helpful_count { 1 }
  end
end
