# frozen_string_literal: true

FactoryBot.define do
  factory :user_verification do
    association :user
    code { rand(1000..9999).to_s }
    channel { "sms" }
    expires_at { 10.minutes.from_now }
    status { false }
    used_at { nil }

    trait :email do
      channel { "email" }
    end

    trait :sms do
      channel { "sms" }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :used do
      status { true }
      used_at { Time.current }
    end

    trait :active do
      expires_at { 1.hour.from_now }
      status { false }
      used_at { nil }
    end
  end
end
