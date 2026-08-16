# frozen_string_literal: true

require "test_helper"

class UserVerificationTest < ActiveSupport::TestCase
  fixtures :users

  test "active scope returns only non-expired unused verifications" do
    user = users(:john) || create(:user)
    # Clean existing verifications to ensure clean test
    user.user_verifications.destroy_all

    user.user_verifications.create!(code: "1111", channel: "sms", expires_at: 1.hour.from_now, status: false)
    user.user_verifications.create!(code: "2222", channel: "sms", expires_at: 1.hour.ago, status: false)
    user.user_verifications.create!(code: "3333", channel: "sms", expires_at: 1.hour.from_now, used_at: Time.current, status: true)

    active = user.user_verifications.active
    assert_equal 1, active.count
    assert_equal "1111", active.first.code
  end

  test "used? returns true when status is true" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.create!(
      code: "1234",
      channel: "sms",
      expires_at: 1.hour.from_now,
      status: true
    )
    assert verification.used?
  end

  test "used? returns true when used_at is present" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.create!(
      code: "1234",
      channel: "sms",
      expires_at: 1.hour.from_now,
      status: false,
      used_at: Time.current
    )
    assert verification.used?
  end

  test "mark_used! updates status and used_at" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.create!(
      code: "1234",
      channel: "sms",
      expires_at: 1.hour.from_now,
      status: false
    )

    verification.mark_used!

    assert verification.status
    assert_not_nil verification.used_at
  end

  test "sms? returns true for sms channel" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.create!(
      code: "1234",
      channel: "sms",
      expires_at: 1.hour.from_now,
      status: false
    )
    assert verification.sms?
    assert_not verification.email?
  end

  test "email? returns true for email channel" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.create!(
      code: "1234",
      channel: "email",
      expires_at: 1.hour.from_now,
      status: false
    )
    assert verification.email?
    assert_not verification.sms?
  end

  test "validates channel inclusion" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.new(
      code: "1234",
      channel: "invalid",
      expires_at: 1.hour.from_now,
      status: false
    )
    assert_not verification.valid?
    assert verification.errors[:channel].any?
  end

  test "validates code presence" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.new(
      channel: "sms",
      expires_at: 1.hour.from_now,
      status: false
    )
    assert_not verification.valid?
    assert verification.errors[:code].any?
  end

  test "validates expires_at presence" do
    user = users(:john) || create(:user)
    verification = user.user_verifications.new(
      code: "1234",
      channel: "sms",
      status: false
    )
    assert_not verification.valid?
    assert verification.errors[:expires_at].any?
  end
end
