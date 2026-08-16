FactoryBot.define do
  factory :shop_social_link do
    association :shop
    association :social_platform
    url { Faker::Internet.url }

    trait :facebook do
      after(:build) do |link|
        link.social_platform = create(:social_platform, name: "Facebook", icon_class: "fab fa-facebook")
      end
      url { "https://facebook.com/#{Faker::Internet.username}" }
    end

    trait :instagram do
      after(:build) do |link|
        link.social_platform = create(:social_platform, name: "Instagram", icon_class: "fab fa-instagram")
      end
      url { "https://instagram.com/#{Faker::Internet.username}" }
    end

    trait :twitter do
      after(:build) do |link|
        link.social_platform = create(:social_platform, name: "Twitter", icon_class: "fab fa-twitter")
      end
      url { "https://twitter.com/#{Faker::Internet.username}" }
    end

    trait :empty_url do
      url { "" }
    end
  end
end
