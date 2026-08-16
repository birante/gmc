FactoryBot.define do
  factory :user do
    first_name { "Jean" }
    last_name { "Doe" }
    sequence(:phone_number) { |n| "77#{(1234567 + n)}" }
    country_code { "SN" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :verified do
      after(:create) do |user|
        # Create a used verification to mark user as verified
        user.user_verifications.create!(
          code: "1234",
          channel: "sms",
          expires_at: 1.hour.from_now,
          status: true,
          used_at: Time.current
        )
      end
    end
  end
end
