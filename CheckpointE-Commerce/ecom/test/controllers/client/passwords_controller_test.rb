# frozen_string_literal: true

require "test_helper"

# Couvre principalement le mécanisme anti-énumération du reset password client :
# pour un téléphone inconnu, l'UX doit être strictement identique à un parcours
# légitime (redirection vers /verify, formulaire OTP affiché, OTP "invalide"
# au lieu d'une boucle de redirect vers /new).
class Client::PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :verified, phone_number: "771234567", country_code: "SN")
    # On stub l'envoi SMS au plus bas niveau : on ne teste pas l'intégration SMS ici.
    Otp::SenderService.stubs(:send_sms).returns(true)
  end

  # ---------------------------------------------------------------------------
  # Anti-énumération : téléphone inconnu
  # ---------------------------------------------------------------------------

  test "POST create avec téléphone inconnu redirige vers verify (pas de boucle)" do
    post client_passwords_path, params: { phone_number: "770000000", country_code: "SN" }

    assert_redirected_to client_verify_password_path
    assert_match(/si ce numéro existe/i, flash[:notice].to_s)
  end

  test "GET verify après un téléphone inconnu rend le formulaire OTP (état dummy)" do
    post client_passwords_path, params: { phone_number: "770000000", country_code: "SN" }
    follow_redirect!

    assert_response :success
    # On doit retomber sur la page OTP (4 inputs de longueur 1), pas sur /new.
    assert_select "input[type=text][maxlength='1']", count: 4
  end

  test "POST check_otp en état dummy renvoie l'erreur OTP standard (anti-leak)" do
    post client_passwords_path, params: { phone_number: "770000000", country_code: "SN" }
    follow_redirect!

    post client_passwords_verify_path,
         params: { otp_code_0: "1", otp_code_1: "2", otp_code_2: "3", otp_code_3: "4" }

    assert_response :unprocessable_entity
    assert_match(/invalide|expir/i, response.body)
  end

  test "le state dummy ne donne JAMAIS accès à edit même avec un code arbitraire" do
    post client_passwords_path, params: { phone_number: "770000000", country_code: "SN" }
    follow_redirect!

    10.times do |i|
      code = i.to_s * 4
      post client_passwords_verify_path,
           params: { otp_code_0: code[0], otp_code_1: code[1], otp_code_2: code[2], otp_code_3: code[3] }
      assert_response :unprocessable_entity, "Code #{code} ne doit jamais valider l'OTP dummy"
    end

    # Et l'accès direct à edit doit échouer (pas de reset_token en session).
    get client_edit_password_path
    assert_redirected_to client_new_password_path
  end

  # ---------------------------------------------------------------------------
  # Flux légitime : téléphone connu
  # ---------------------------------------------------------------------------

  test "POST create avec téléphone connu envoie un OTP et redirige vers verify" do
    Otp::Generator.stubs(:generate_from_config).returns("4242")
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)

    assert_difference -> { @user.user_verifications.count }, 1 do
      post client_passwords_path, params: { phone_number: @user.phone_number, country_code: @user.country_code }
    end

    assert_redirected_to client_verify_password_path
    assert_match(/code de vérification.*sms/i, flash[:notice].to_s)
  end

  test "GET verify après un téléphone connu rend le formulaire OTP" do
    Otp::Generator.stubs(:generate_from_config).returns("4242")
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post client_passwords_path, params: { phone_number: @user.phone_number, country_code: @user.country_code }
    follow_redirect!

    assert_response :success
    assert_select "input[type=text][maxlength='1']", count: 4
  end

  test "POST check_otp avec bon code émet un reset_token et redirige vers edit" do
    Otp::Generator.stubs(:generate_from_config).returns("4242")
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post client_passwords_path, params: { phone_number: @user.phone_number, country_code: @user.country_code }
    follow_redirect!

    post client_passwords_verify_path,
         params: { otp_code_0: "4", otp_code_1: "2", otp_code_2: "4", otp_code_3: "2" }

    assert_redirected_to client_edit_password_path
  end

  test "POST check_otp avec mauvais code retourne 422 avec message d'erreur" do
    Otp::Generator.stubs(:generate_from_config).returns("4242")
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post client_passwords_path, params: { phone_number: @user.phone_number, country_code: @user.country_code }
    follow_redirect!

    post client_passwords_verify_path,
         params: { otp_code_0: "9", otp_code_1: "9", otp_code_2: "9", otp_code_3: "9" }

    assert_response :unprocessable_entity
    assert_match(/invalide|expir/i, response.body)
  end

  # ---------------------------------------------------------------------------
  # Garde-fou : sans aucun state, /verify renvoie vers /new
  # ---------------------------------------------------------------------------

  test "GET verify sans aucune session de reset redirige vers /new" do
    get client_verify_password_path

    assert_redirected_to client_new_password_path
    assert_match(/saisir.*numéro/i, flash[:alert].to_s)
  end
end
