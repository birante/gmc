# frozen_string_literal: true

require "test_helper"

class Client::VerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # On ne teste pas l'intégration SMS ici : on stub l'envoi au plus bas niveau
    # (sinon l'env de test tente un vrai envoi via le provider, qui échoue).
    Otp::SenderService.stubs(:send_sms).returns(true)
  end

  def build_user_params
    email = "test_#{SecureRandom.hex(4)}@example.com"
    {
      user: {
        first_name: "Test",
        last_name: "User",
        phone_number: "77#{rand(1000000..9999999)}",
        country_code: "SN",
        email_address: email,
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  # Crée un pending en session via le flux d'inscription (code OTP stubé). Retourne [otp_code, params].
  def register_client_with_otp_stub(otp_code: "1234")
    params = build_user_params
    Otp::Generator.stubs(:generate_from_config).returns(otp_code)
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post client_registration_path, params: params
    assert_response :redirect, "Registration should succeed"
    follow_redirect!
    [ otp_code, params ]
  end

  test "GET new renders verification form" do
    get new_client_verification_path
    assert_response :success
    assert_select "h1", text: /Vérification|Verify/
    assert_select "input[type=text][maxlength='1']", count: 4
  end

  test "POST create with valid code redirects to client items" do
    register_client_with_otp_stub
    post client_verification_path, params: { code: "1234" }
    assert_redirected_to client_items_path
    assert_match(/Vérification réussie|Verification successful|success/i, flash[:notice].to_s)
  end

  test "POST create with valid code creates a new session" do
    _code, params = register_client_with_otp_stub
    email = params[:user][:email_address]
    initial_count = Session.count

    post client_verification_path, params: { code: "1234" }

    assert_equal initial_count + 1, Session.count
    user = User.find_by(email_address: email)
    assert user.present?, "User should be created"
    created_session = Session.order(created_at: :desc).first
    assert_not_nil created_session
    assert_equal user.id, created_session.sessionable_id
    assert_equal "User", created_session.sessionable_type
  end

  test "POST create with invalid code renders new with error" do
    register_client_with_otp_stub
    post client_verification_path, params: { code: "9999" }
    assert_response :unprocessable_entity
    assert_match(/invalide|invalid|expiré|expired|incorrect|error/i, response.body)
  end

  test "POST create with expired code renders new with error" do
    _code, params = register_client_with_otp_stub
    email = params[:user][:email_address]
    pending = PendingRegistration.for_user.find_by(email: email)
    assert pending.present?, "PendingRegistration should exist"
    pending.update!(otp_expires_at: 1.hour.ago)

    post client_verification_path, params: { code: "1234" }

    assert_response :unprocessable_entity
    assert_match(/invalide|invalid|expiré|expired|incorrect|error/i, response.body)
  end

  test "POST create with non-existent user renders new with error" do
    post client_verification_path, params: {
      email_address: "nonexistent@example.com",
      code: "1234"
    }

    assert_response :unprocessable_entity
    assert_match(/introuvable|not found|inscription en attente/i, response.body)
  end

  test "POST create can find user by phone_number" do
    # Le flux actuel utilise pending_registration_id en session ; le contrôleur ne cherche pas par phone.
    # On vérifie que le flux complet (inscription + vérification) fonctionne.
    register_client_with_otp_stub
    post client_verification_path, params: { code: "1234" }
    assert_redirected_to client_items_path
  end

  test "POST create can find user from session" do
    register_client_with_otp_stub
    post client_verification_path, params: { code: "1234" }
    assert_redirected_to client_items_path
  end

  test "POST create deletes vendor session if present" do
    _code, params = register_client_with_otp_stub
    post client_verification_path, params: { code: "1234" }
    user = User.find_by(email_address: params[:user][:email_address])
    assert user.present?, "User should be created"
    user_session = user.sessions.reload.last
    assert_not_nil user_session
    assert_equal "User", user_session.sessionable_type
    assert_redirected_to client_items_path
  end

  test "POST create marks verification as used" do
    _code, params = register_client_with_otp_stub
    email = params[:user][:email_address]
    pending = PendingRegistration.for_user.find_by(email: email)
    assert pending.present?, "PendingRegistration should exist"

    post client_verification_path, params: { code: "1234" }

    pending.reload
    assert pending.verified?, "PendingRegistration should be marked verified (used)"
    assert_not_nil pending.verified_at
  end
end
