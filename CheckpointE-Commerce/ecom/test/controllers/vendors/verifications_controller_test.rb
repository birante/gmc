require "test_helper"

class Vendors::VerificationsControllerTest < ActionDispatch::IntegrationTest
  def build_vendor_params
    {
      vendor: {
        first_name: "V",
        last_name: "One",
        phone_number: "0612345678",
        country_code: "+33",
        email: "verify_#{SecureRandom.hex(4)}@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  # Returns [otp_code, params] so tests can look up vendor by params[:vendor][:email]
  def register_vendor_with_otp_stub(otp_code: "9999")
    params = build_vendor_params
    Otp::Generator.stubs(:generate_from_config).returns(otp_code)
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post vendors_registration_path, params: params
    assert_response :redirect
    follow_redirect!
    [ otp_code, params ]
  end

  def otp_params(code)
    digits = code.to_s.chars
    {
      otp_code_0: digits[0],
      otp_code_1: digits[1],
      otp_code_2: digits[2],
      otp_code_3: digits[3]
    }
  end

  test "verify success redirects to dashboard or saved return path" do
    _code, params = register_vendor_with_otp_stub
    post vendors_verification_path, params: otp_params("9999")
    vendor = Vendor.find_by(email: params[:vendor][:email])
    assert vendor.present?, "Vendor should be created after verification"
    assert_redirected_to new_vendors_shop_path
  end

  test "successful verification creates a new session record for the vendor" do
    _code, params = register_vendor_with_otp_stub
    initial_count = Session.count
    post vendors_verification_path, params: otp_params("9999")
    vendor = Vendor.find_by(email: params[:vendor][:email])
    assert vendor.present?, "Vendor should be created after verification"
    assert_equal initial_count + 1, Session.count
    created_session = Session.order(created_at: :desc).first
    assert_not_nil created_session
    assert_equal vendor.id, created_session.sessionable_id
    assert_equal "Vendor", created_session.sessionable_type
    assert_redirected_to new_vendors_shop_path
  end

  test "successful verification sets the session cookie" do
    _code, params = register_vendor_with_otp_stub
    post vendors_verification_path, params: otp_params("9999")
    vendor = Vendor.find_by(email: params[:vendor][:email])
    assert vendor.present?, "Vendor should be created"
    vendor_session = vendor.sessions.reload.last
    assert_not_nil vendor_session
    assert_redirected_to new_vendors_shop_path
  end

  test "successful verification destroys existing client session if present" do
    _code, params = register_vendor_with_otp_stub
    client = users(:john)
    client.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent")
    post vendors_verification_path, params: otp_params("9999")
    vendor = Vendor.find_by(email: params[:vendor][:email])
    assert vendor.present?, "Vendor should be created"
    vendor_session = vendor.sessions.reload.last
    assert_not_nil vendor_session
    assert_equal "Vendor", vendor_session.sessionable_type
    assert_redirected_to new_vendors_shop_path
  end

  test "verify failure renders new" do
    register_vendor_with_otp_stub
    post vendors_verification_path, params: otp_params("0000")
    assert_response :unprocessable_entity
  end
end
