FactoryBot.define do
  factory :subscription_payment do
    shop
    plan
    payment_method { PaymentMethod.find_by(code: "paydunya") || association(:payment_method, code: "paydunya", is_active: true) }
    amount { 50000 }
    status { :pending }
    withdraw_mode { "wave-senegal" }
    payment_type { "PAR" }
    paydunya_token { nil }
    paydunya_invoice_url { nil }
    transaction_id { "SUB-TXN-#{Time.current.to_i}-#{SecureRandom.hex(4).upcase}" }
    paid_at { nil }
    provider_response { {} }
    failure_reason { nil }
  end
end
