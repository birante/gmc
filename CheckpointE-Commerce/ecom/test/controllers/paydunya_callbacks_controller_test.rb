require "test_helper"
require "ostruct"

class PaydunyaCallbacksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @order = orders(:one)
    @payment_method = payment_methods(:paydunya)
    @payment = Payment.create!(
      order: @order,
      payment_method: @payment_method,
      amount: 10000,
      status: :pending,
      user_id: @user.id,
      transaction_id: "PAYDUNYA-#{SecureRandom.hex(8)}",
      paydunya_token: "test_ABC123",
      payment_type: "PAR"
    )

    # Sign in the user for authenticated actions
    @user_session = @user.sessions.create!(user_agent: "Test", ip_address: "127.0.0.1")

    # Stub the authentication to always set Current.session
    PaydunyaCallbacksController.any_instance.stubs(:resume_session).returns(@user_session)
    Current.stubs(:session).returns(@user_session)
  end

  # Tests pour success callback
  test "should redirect to orders list on successful payment" do
    # Mock du service de vérification
    PaymentServices::PaydunyaService.any_instance.stubs(:check_payment_status).returns(
      OpenStruct.new(
        success?: true,
        payment: @payment
      )
    )

    @payment.update(status: :completed)

    get paydunya_success_url, params: { token: @payment.paydunya_token }

    assert_redirected_to client_orders_path
    assert_match /Paiement confirmé/, flash[:notice]
  end

  test "should handle payment not found on success" do
    get paydunya_success_url, params: { token: "invalid_token" }

    assert_redirected_to root_path
    assert_match /introuvable/, flash[:alert]
  end

  test "should handle failed payment verification" do
    # Mock du service qui échoue
    PaymentServices::PaydunyaService.any_instance.stubs(:check_payment_status).returns(
      OpenStruct.new(
        success?: false,
        payment: @payment,
        errors: [ "Payment verification failed" ]
      )
    )

    get paydunya_success_url, params: { token: @payment.paydunya_token }

    assert_redirected_to client_orders_path
    assert_match /n'a pas pu être confirmé/, flash[:alert]
  end

  # Tests pour cancel callback
  test "should handle payment cancellation" do
    get paydunya_cancel_url, params: { token: @payment.paydunya_token }

    @payment.reload
    assert_equal "failed", @payment.status

    @order.reload
    assert_equal "canceled", @order.status

    assert_redirected_to client_orders_path
    assert_match /annulé/, flash[:alert]
  end

  test "should handle cancellation with invalid token" do
    get paydunya_cancel_url, params: { token: "invalid_token" }

    assert_redirected_to root_path
    assert_match /introuvable/, flash[:alert]
  end

  test "should handle cancellation with missing token" do
    get paydunya_cancel_url

    assert_redirected_to root_path
    assert_match /Token manquant/, flash[:alert]
  end

  # Tests pour IPN (Instant Payment Notification)
  test "should process IPN notification successfully" do
    # Mock du service de vérification
    PaymentServices::PaydunyaService.any_instance.stubs(:check_payment_status).returns(
      OpenStruct.new(
        success?: true,
        payment: @payment
      )
    )

    post paydunya_ipn_url, params: {
      data: {
        token: @payment.paydunya_token,
        status: "completed"
      }
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
  end

  test "should handle IPN with invalid token" do
    post paydunya_ipn_url, params: {
      data: {
        token: "invalid_token"
      }
    }, as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
  end

  test "should handle IPN with missing token" do
    post paydunya_ipn_url, params: {
      data: {}
    }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
    assert_match /Token missing/, json_response["message"]
  end

  test "should handle IPN verification failure" do
    PaymentServices::PaydunyaService.any_instance.stubs(:check_payment_status).returns(
      OpenStruct.new(
        success?: false,
        payment: @payment,
        errors: [ "Verification failed" ]
      )
    )

    post paydunya_ipn_url, params: {
      data: {
        token: @payment.paydunya_token
      }
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
  end

  # Tests pour charge PSR
  test "should charge PSR payment with valid code" do
    @payment.update(payment_type: "PSR")

    PaymentServices::PaydunyaService.any_instance.stubs(:charge_onsite_invoice).returns(
      OpenStruct.new(
        success?: true,
        payment: @payment,
        redirect_url: "https://paydunya.com/receipt/test_ABC123"
      )
    )

    post paydunya_charge_url, params: {
      token: @payment.paydunya_token,
      confirmation_code: "123456"
    }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_match /confirmé/, json_response["message"]
  end

  test "should reject charge with invalid confirmation code" do
    @payment.update(payment_type: "PSR")

    PaymentServices::PaydunyaService.any_instance.stubs(:charge_onsite_invoice).returns(
      OpenStruct.new(
        success?: false,
        payment: @payment,
        errors: [ "Invalid confirmation code" ]
      )
    )

    post paydunya_charge_url, params: {
      token: @payment.paydunya_token,
      confirmation_code: "000000"
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
  end

  test "should require confirmation code for charge" do
    post paydunya_charge_url, params: {
      token: @payment.paydunya_token
    }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
    assert_match /confirmation requis/, json_response["error"]
  end

  test "should handle charge with payment not found" do
    post paydunya_charge_url, params: {
      token: "invalid_token",
      confirmation_code: "123456"
    }, as: :json

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_not json_response["success"]
  end

  # Tests de sécurité
  test "should not verify CSRF token for IPN" do
    # L'IPN doit fonctionner sans CSRF token car c'est un webhook externe
    # Mock the service to avoid real HTTP calls
    PaymentServices::PaydunyaService.any_instance.stubs(:check_payment_status).returns(
      OpenStruct.new(
        success?: true,
        payment: @payment
      )
    )

    assert_nothing_raised do
      post paydunya_ipn_url, params: {
        data: {
          token: @payment.paydunya_token
        }
      }, as: :json
    end
  end

  test "should log callback events" do
    # Just verify the action executes without error
    PaymentServices::PaydunyaService.any_instance.stubs(:check_payment_status).returns(
      OpenStruct.new(
        success?: true,
        payment: @payment
      )
    )
    @payment.update(status: :completed)

    assert_nothing_raised do
      get paydunya_success_url, params: { token: @payment.paydunya_token }
    end
  end
end
