FactoryBot.define do
  factory :shop_contact do
    association :shop
    country_code { "221" }
    phone_number { "77#{rand(1000000..9999999)}" }
    is_whatsapp { false }

    trait :with_whatsapp do
      is_whatsapp { true }
    end

    trait :with_different_country do
      country_code { "33" }
      phone_number { "123456789" }
    end
  end
end
