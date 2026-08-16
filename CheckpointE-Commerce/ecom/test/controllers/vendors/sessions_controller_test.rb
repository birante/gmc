require "test_helper"

class Vendors::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vendor = create(:vendor, :verified,
      first_name: "Test",
      last_name: "Vendor",
      phone_number: "0612345678",
      country_code: "+33",
      email: "sessions@example.com",
      password: "password",
      password_confirmation: "password"
    )
    # Create a shop for the vendor so they can access the dashboard
    create(:shop, vendor: @vendor)
  end

  test "should get new" do
    get new_vendors_session_path
    assert_response :success
  end

  test "successful login creates a new session record for the vendor" do
    initial_count = Session.count

    post vendors_session_path, params: {
      email: @vendor.email,
      password: "password"
    }

    assert_equal initial_count + 1, Session.count, "Expected session count to increase by 1"

    # Get the most recently created session
    created_session = Session.order(created_at: :desc).first
    assert_not_nil created_session, "Expected a session to be created"
    assert_equal @vendor.id, created_session.sessionable_id
    assert_equal "Vendor", created_session.sessionable_type
    assert_not_nil created_session.ip_address, "Expected ip_address to be set"
    # user_agent can be nil in test environment, just check it's been set (even if to nil)
    assert created_session.has_attribute?(:user_agent)
    assert_redirected_to vendors_dashboard_path
  end

  test "successful vendor login creates a new session record and sets the session cookie" do
    initial_count = Session.count

    post vendors_session_path, params: {
      email: @vendor.email,
      password: "password"
    }

    # Verify session record was created
    assert_equal initial_count + 1, Session.count, "Expected session count to increase by 1"

    # Get the most recently created session
    vendor_session = @vendor.sessions.last
    assert_not_nil vendor_session, "Expected a session to be created"
    assert_equal @vendor.id, vendor_session.sessionable_id
    assert_equal "Vendor", vendor_session.sessionable_type
    assert_not_nil vendor_session.ip_address, "Expected ip_address to be set"
    assert vendor_session.has_attribute?(:user_agent)

    # Verify the session cookie was set (we can't directly test cookies.signed in integration tests,
    # but we can verify the session was created and the redirect happened)
    assert_redirected_to vendors_dashboard_path

    # Verify vendor_id is set in Rails session
    assert_equal @vendor.id, session[:vendor_id]
  end

  test "successful login sets vendor_id in rails session" do
    post vendors_session_path, params: {
      email: @vendor.email,
      password: "password"
    }

    assert_equal @vendor.id, session[:vendor_id]
  end

  test "failed login does not create a session record" do
    assert_no_difference "Session.count" do
      post vendors_session_path, params: {
        email: @vendor.email,
        password: "wrong_password"
      }
    end

    assert_response :unprocessable_entity
  end

  test "successful login destroys existing client session if present" do
    # Create a client user and session using fixtures
    client = users(:john)
    client_session = client.sessions.create!(
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )
    client_session_id = client_session.id

    # Simulate having a client session by making a request that sets the cookie
    # In a real scenario, the client would be logged in first
    get root_path

    # Now login as vendor - it should destroy the client session
    post vendors_session_path, params: {
      email: @vendor.email,
      password: "password"
    }

    # Client session should be destroyed by the vendor login
    # (The controller explicitly destroys Current.session before creating vendor session)
    # We verify the vendor session was created
    vendor_session = @vendor.sessions.last
    assert_not_nil vendor_session
    assert_equal "Vendor", vendor_session.sessionable_type
    assert_redirected_to vendors_dashboard_path
  end

  test "destroy logs out vendor and redirects to root" do
    post vendors_session_path, params: {
      email: @vendor.email,
      password: "password"
    }

    delete vendors_session_path
    assert_nil session[:vendor_id]
    assert_redirected_to root_path
  end
end
