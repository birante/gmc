require "test_helper"

class Vendors::RegistrationServiceTest < ActiveSupport::TestCase
  fixtures :vendors

  setup do
    @attrs = {
      first_name: "Svc",
      last_name: "User",
      phone_number: "0612345678",
      country_code: "+33",
      email: "svc_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  test "create sends email verification by default" do
    result = Vendors::RegistrationService.create(@attrs, "email")
    assert result.success, "Expected success but got errors: #{result.errors.inspect}"
    v = Vendor.find_by(email: @attrs[:email])
    assert v.nil?, "Vendor should not exist yet"
    pending = PendingRegistration.for_vendor.find_by(email: @attrs[:email])
    assert pending.present?
    assert_equal 1, PendingRegistration.for_vendor.where(email: @attrs[:email]).count
    assert_equal "email", pending.channel
    assert_equal 4, pending.otp_code.length
  end

  test "create sends sms verification when channel=sms" do
    result = Vendors::RegistrationService.create(@attrs, "sms")
    assert result.success, "Expected success but got errors: #{result.errors.inspect}"
    pending = PendingRegistration.for_vendor.find_by(email: @attrs[:email])
    assert pending.present?
    assert_equal "sms", pending.channel
    assert_equal 4, pending.otp_code.length
  end

  test "verify invalid or expired returns failure" do
    result = Vendors::RegistrationService.create(@attrs, "email")
    assert result.success
    pending = result.pending_registration
    pending.update!(otp_expires_at: 1.hour.ago)

    result = Vendors::RegistrationService.verify(pending.id, pending.otp_code)
    assert_not result.success
    assert_includes result.errors, "code_expired"
  end
end
