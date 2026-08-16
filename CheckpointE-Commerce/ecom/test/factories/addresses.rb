FactoryBot.define do
  factory :address do
    association :user
    street_address { "123 Rue de la République" }
    city { "Dakar" }
    postal_code { "10200" }
    country { "SN" }
    is_default { false }
    latitude { 14.6937 }
    longitude { -17.4441 }
  end
end
