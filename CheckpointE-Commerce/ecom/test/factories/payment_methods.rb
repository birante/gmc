FactoryBot.define do
  factory :payment_method do
    code { "MyString" }
    name { "MyString" }
    provider { "MyString" }
    method_type { "MyString" }
    is_active { false }
  end
end
