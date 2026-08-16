require "test_helper"

class VendorVerificationTest < ActiveSupport::TestCase
  fixtures :vendors

  test "active scope returns only non-expired unused verifications" do
    v = vendors(:one)
    # Clean existing verifications to ensure clean test
    v.vendor_verifications.destroy_all

    v.vendor_verifications.create!(code: "11111", channel: "email", expires_at: 1.hour.from_now)
    v.vendor_verifications.create!(code: "22222", channel: "email", expires_at: 1.hour.ago)
    v.vendor_verifications.create!(code: "33333", channel: "email", expires_at: 1.hour.from_now, used_at: Time.current)

    active = v.vendor_verifications.active
    assert_equal 1, active.count
    assert_equal "11111", active.first.code
  end
end
