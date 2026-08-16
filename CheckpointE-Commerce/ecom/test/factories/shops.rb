FactoryBot.define do
  factory :shop do
    association :vendor
    name { Faker::Company.unique.name }
    slug { name.parameterize }
    address { Faker::Address.full_address }
    description { Faker::Lorem.sentence }
    primary_color { "#3B82F6" }
    secondary_color { "#EF4444" }
    status { "pending" }
    code { "SHOP#{SecureRandom.hex(3).upcase}" }

    trait :active do
      status { "active" }
    end

    trait :suspended do
      status { "suspended" }
    end

    trait :deactivate do
      status { "deactivate" }
    end

    trait :with_contacts do
      after(:create) do |shop|
        create(:shop_contact, shop: shop)
      end
    end

    trait :with_legal_info do
      after(:create) do |shop|
        create(:shop_legal_info, shop: shop)
      end
    end

    trait :with_social_links do
      after(:create) do |shop|
        create_list(:shop_social_link, 3, shop: shop)
      end
    end

    trait :complete do
      after(:create) do |shop|
        create(:shop_contact, shop: shop)
        create(:shop_legal_info, shop: shop)
        create_list(:shop_social_link, 2, shop: shop)
      end
    end

    trait :with_subscription do
      after(:create) do |shop|
        plan = Plan.find_by(code: "ACCESS") || create(:plan, code: "ACCESS", name: "Access")
        create(:subscription, shop: shop, plan: plan)
      end
    end
  end
end
