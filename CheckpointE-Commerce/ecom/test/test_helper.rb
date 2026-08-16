ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Ensure OTP configuration is correct for tests
    setup do
      # Force reset OTP configuration for every test
      # Tous les codes de vérification doivent être de 4 chiffres
      Rails.application.config.vendor_otp.length = 4
      Rails.application.config.vendor_otp.ttl_seconds = 10.minutes.to_i
      Rails.application.config.vendor_otp.default_channel = "email"

      # User OTP configuration for tests
      Rails.application.config.user_otp.length = 4
      Rails.application.config.user_otp.ttl_seconds = 10.minutes.to_i
      Rails.application.config.user_otp.default_channel = "sms"

      # Set locale to English for tests to match expected error messages
      I18n.locale = :en

      # Stub SMS HTTP requests by default to avoid real API calls
      stub_sms_requests
    end

    # Helper method to stub SMS API requests
    def stub_sms_requests
      stub_request(:post, /lamsms\.lafricamobile\.com/)
        .to_return(
          status: 200,
          body: { success: true, message: "SMS sent" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    # Helper method to create a verified vendor
    def create_verified_vendor(attributes = {})
      vendor = create(:vendor, attributes)
      # Create a used verification to mark vendor as verified
      vendor.vendor_verifications.create!(
        code: "1234",
        channel: "email",
        expires_at: 1.hour.from_now,
        status: true,
        used_at: Time.current
      )
      # Ensure vendor is active (use update_column to bypass validations)
      vendor.update_column(:status, "active")
      vendor.reload
      vendor
    end

    # Helper method to create a verified user
    def create_verified_user(attributes = {})
      user = create(:user, attributes)
      # Create a used verification to mark user as verified
      user.user_verifications.create!(
        code: "1234",
        channel: "sms",
        expires_at: 1.hour.from_now,
        status: true,
        used_at: Time.current
      )
      user
    end

    # Add more helper methods to be used by all tests here...
  end
end
