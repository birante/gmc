# frozen_string_literal: true

require "test_helper"

class Clients::RegistrationServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @attrs = {
      first_name: "Test",
      last_name: "User",
      phone_number: "77#{rand(1000000..9999999)}",
      country_code: "SN",
      email_address: "test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  test "create sends email verification when channel=email" do
    result = Clients::RegistrationService.create(@attrs, "email")
    assert result.success, "Expected success but got errors: #{result.errors.inspect}"
    user = User.find_by(email_address: @attrs[:email_address])
    assert user.nil?, "User should not exist yet (only PendingRegistration)"
    pending = PendingRegistration.for_user.find_by(email: @attrs[:email_address])
    assert pending.present?, "PendingRegistration should be created"
    assert_equal 1, PendingRegistration.for_user.where(email: @attrs[:email_address]).count
    assert_equal "email", pending.channel
    assert_equal 4, pending.otp_code.length
  end

  test "create sends sms verification when SMS is enabled" do
    ENV["SEND_SMS_ENABLED"] = "true"
    result = Clients::RegistrationService.create(@attrs, "sms")
    assert result.success, "Expected success but got errors: #{result.errors.inspect}"
    pending = PendingRegistration.for_user.find_by(email: @attrs[:email_address])
    assert pending.present?
    assert_equal 1, PendingRegistration.for_user.where(email: @attrs[:email_address]).count
  ensure
    ENV.delete("SEND_SMS_ENABLED")
  end

  test "create falls back to email if SMS is disabled" do
    fake_sms_service = Class.new do
      def send_sms(to:, message:, sms_type:)
        raise Sms::SmsService::SmsDisabledError, "SMS disabled"
      end
    end.new
    Sms::SmsService.stubs(:new).returns(fake_sms_service)

    result = Clients::RegistrationService.create(@attrs, "sms")
    assert result.success, "Expected success but got errors: #{result.errors.inspect}"
    pending = PendingRegistration.for_user.find_by(email: @attrs[:email_address])
    assert pending.present?
  end

  test "create fails validation if phone_number is missing" do
    attrs_without_phone = @attrs.merge(phone_number: "")
    result = Clients::RegistrationService.create(attrs_without_phone, "sms")
    assert_not result.success
  end

  test "create fails validation if password is shorter than 8 characters" do
    attrs_with_short_password = @attrs.merge(password: "1234567", password_confirmation: "1234567")

    assert_no_difference("PendingRegistration.count") do
      result = Clients::RegistrationService.create(attrs_with_short_password, "sms")
      assert_not result.success
      assert_includes result.errors[:password], "is too short (minimum is 8 characters)"
    end
  end

  test "verify with valid code returns success" do
    result = Clients::RegistrationService.create(@attrs, "email")
    assert result.success
    pending = result.pending_registration
    code = pending.otp_code

    result = Clients::RegistrationService.verify(pending.id, code)

    assert result.success
    pending.reload
    assert pending.verified?
    assert_not_nil pending.verified_at
    user = User.find_by(email_address: @attrs[:email_address])
    assert user.present?
  end

  test "verify with invalid code returns failure" do
    result = Clients::RegistrationService.create(@attrs, "email")
    assert result.success
    pending = result.pending_registration

    result = Clients::RegistrationService.verify(pending.id, "9999")

    assert_not result.success
    assert_includes result.errors, "invalid_code"
  end

  test "verify with expired code returns failure" do
    result = Clients::RegistrationService.create(@attrs, "email")
    assert result.success
    pending = result.pending_registration
    pending.update!(otp_expires_at: 1.hour.ago)

    result = Clients::RegistrationService.verify(pending.id, pending.otp_code)

    assert_not result.success
    assert_includes result.errors, "code_expired"
  end

  test "verify with non-existent user returns failure" do
    result = Clients::RegistrationService.verify(999999, "1234")
    assert_not result.success
    assert_includes result.errors, "pending_registration_not_found"
  end

  test "verify can accept pending_registration id as integer" do
    result = Clients::RegistrationService.create(@attrs, "email")
    assert result.success
    pending = result.pending_registration
    code = pending.otp_code

    result = Clients::RegistrationService.verify(pending.id, code)
    assert result.success
  end

  test "generate_otp_code_with_length generates correct length code" do
    code = Clients::RegistrationService.generate_otp_code_with_length(4)
    assert_equal 4, code.length
    assert_match(/\A\d{4}\z/, code)
  end
end
