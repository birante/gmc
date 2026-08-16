FactoryBot.define do
  factory :social_platform do
    name { Faker::Internet.domain_word.capitalize }
    icon_class { "fab fa-#{name.downcase}" }
    position { rand(1..10) }
    is_active { true }

    trait :inactive do
      is_active { false }
    end

    trait :facebook do
      name { "Facebook" }
      icon_class { "fab fa-facebook" }
      position { 1 }
    end

    trait :instagram do
      name { "Instagram" }
      icon_class { "fab fa-instagram" }
      position { 2 }
    end

    trait :twitter do
      name { "Twitter" }
      icon_class { "fab fa-twitter" }
      position { 3 }
    end
  end
end
