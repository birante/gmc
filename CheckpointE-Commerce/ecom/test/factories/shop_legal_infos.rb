FactoryBot.define do
  factory :shop_legal_info do
    association :shop
    legal_form { "SARL" }
    rc_number { "SN-DKR-2023-B-#{rand(10000..99999)}" }
    ninea_number { "#{rand(100000000..999999999)}" }

    trait :sa do
      legal_form { "SA" }
    end

    trait :suarl do
      legal_form { "SUARL" }
    end

    trait :without_ninea do
      ninea_number { nil }
    end
  end
end
