FactoryBot.define do
  factory :payment do
    order { nil }
    payment_method { nil }
    transaction_id { "MyString" }
    status { 1 }
    amount { "9.99" }
    paid_at { "2025-10-25 12:29:00" }
    user_id { 1 }
  end
end
