FactoryBot.define do
  factory :payout do
    shop { nil }
    amount { "9.99" }
    status { "MyString" }
    reference_number { "MyString" }
    paid_at { "2025-12-21 12:04:00" }
    payout_month { 1 }
    payout_year { 1 }
  end
end
