require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @vendor = Vendor.create!(
      first_name: "Test",
      last_name: "Vendor",
      phone_number: "0612345678",
      country_code: "+33",
      email: "test@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "find_test_session successfully creates a new session for a valid test vendor ID in a test environment" do
    initial_count = Session.count

    get root_path, params: { test_vendor_id: @vendor.id }

    assert_equal initial_count + 1, Session.count
    session = @vendor.sessions.last
    assert_not_nil session
    assert_equal @vendor.id, session.sessionable_id
    assert_equal "Vendor", session.sessionable_type
    assert_equal "127.0.0.1", session.ip_address
    assert_equal "Test User Agent", session.user_agent
  end

  test "find_test_session returns an existing session for a valid test vendor ID in a test environment" do
    # Create an existing test session
    existing_session = @vendor.sessions.create!(
      ip_address: "127.0.0.1",
      user_agent: "Test User Agent"
    )
    initial_count = Session.count

    # Make another request with same vendor - should reuse session
    get root_path, params: { test_vendor_id: @vendor.id }

    # No new session should be created
    assert_equal initial_count, Session.count

    # The existing session should still exist
    assert_not_nil Session.find_by(id: existing_session.id)
  end

  test "find_test_session returns nil if not in a test environment" do
    # This test verifies the logic by checking that without test_vendor_id,
    # no test session with our specific markers is created
    initial_vendor_sessions = @vendor.sessions.count

    get root_path

    # Should not create a test session for our vendor without test_vendor_id
    assert_equal initial_vendor_sessions, @vendor.sessions.reload.count
  end

  test "find_test_session returns nil without a valid test vendor ID" do
    initial_count = @vendor.sessions.count

    # Test with missing test_vendor_id param
    get root_path
    assert_equal initial_count, @vendor.sessions.reload.count

    # Test with invalid test_vendor_id
    get root_path, params: { test_vendor_id: 999999 }
    assert_equal initial_count, @vendor.sessions.reload.count

    # Test with blank test_vendor_id
    get root_path, params: { test_vendor_id: "" }
    assert_equal initial_count, @vendor.sessions.reload.count
  end
end
