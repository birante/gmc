FactoryBot.define do
  factory :vendor do
    first_name { "John" }
    last_name { "Doe" }
    email { Faker::Internet.unique.email }
    phone_number { "77#{rand(1000000..9999999)}" }
    country_code { "221" }
    password { "password123" }
    password_confirmation { "password123" }
    # Don't set status in base factory - let enum default handle it

    trait :inactive do
      status { "inactive" }
    end

    trait :pending do
      status { "pending" }
    end

    trait :verified do
      after(:build) do |vendor|
        # Set status during build
        vendor.status = :active
      end

      after(:create) do |vendor|
        # Create a used verification to mark vendor as verified
        # The verified? method checks: status == "active" && vendor_verifications.exists?(status: true)
        vendor.vendor_verifications.create!(
          code: "1234",
          channel: "email",
          expires_at: 1.hour.from_now,
          status: true,
          used_at: Time.current
        )

        # Ensure status is active - enum should handle the conversion
        vendor.update!(status: :active) if vendor.status != "active"
        vendor.reload
      end
    end

    trait :with_shops do
      after(:create) do |vendor|
        create_list(:shop, 2, vendor: vendor)
      end
    end
  end
end
