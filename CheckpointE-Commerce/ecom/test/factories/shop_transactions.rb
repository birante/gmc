FactoryBot.define do
  factory :shop_transaction do
    shop { nil }
    order { nil }
    payout { nil }
    amount { "9.99" }
    transaction_type { "MyString" }
    description { "MyString" }
    metadata { "" }
  end
end
