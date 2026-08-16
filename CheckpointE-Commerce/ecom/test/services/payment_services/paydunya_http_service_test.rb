require "test_helper"
require "webmock/minitest"

module PaymentServices
  class PaydunyaHttpServiceTest < ActiveSupport::TestCase
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
        transaction_id: "TEST-#{SecureRandom.hex(8)}"
      )

      # Stub des variables d'environnement pour les tests avec les nouvelles valeurs par défaut
      # Utiliser des stubs spécifiques pour chaque clé avec les nouvelles valeurs par défaut
      ENV.stubs(:fetch).with("PAYDUNYA_MASTER_KEY", "qmR4BzHY-Pxvj-C89u-8B0G-4MdkKeygwCIe").returns("test_master_key")
      ENV.stubs(:fetch).with("PAYDUNYA_PRIVATE_KEY", "test_private_Oswl7zByAb3CcrKwKKl1PChnZ9L").returns("test_private_key")
      ENV.stubs(:fetch).with("PAYDUNYA_TOKEN", "ZIZYuDDbEOvVRYeSbUUp").returns("test_token")
      ENV.stubs(:fetch).with("PAYDUNYA_MODE", "test").returns("test")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_NAME", "aa").returns("test_store_name")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_TAGLINE", "Votre marketplace en ligne").returns("Votre marketplace en ligne")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_ADDRESS", "Dakar, Sénégal").returns("Dakar, Sénégal")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_PHONE", "+221776857298").returns("+221776857298")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_LOGO", "").returns("")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_URL", "http://localhost:3000").returns("http://localhost:3000")

      @service = PaymentServices::PaydunyaHttpService.new(
        payment: @payment,
        order: @order,
        user: @user
      )
    end

    test "should create checkout invoice successfully" do
      # Mock de la réponse PayDunya réussie
      stub_request(:post, "https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create")
        .with(
          headers: {
            "Content-Type" => "application/json",
            "PAYDUNYA-MASTER-KEY" => "test_master_key",
            "PAYDUNYA-PRIVATE-KEY" => "test_private_key",
            "PAYDUNYA-TOKEN" => "test_token"
          }
        )
        .to_return(
          status: 200,
          body: {
            response_code: "00",
            response_text: "https://paydunya.com/sandbox-checkout/invoice/test_ABC123",
            description: "Checkout Invoice Created",
            token: "test_ABC123"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = @service.create_checkout_invoice

      assert result.success?
      assert_equal "test_ABC123", result.token
      assert_equal "https://paydunya.com/sandbox-checkout/invoice/test_ABC123", result.redirect_url

      # Vérifier que le paiement a été mis à jour
      @payment.reload
      assert_equal "test_ABC123", @payment.paydunya_token
      assert_equal "https://paydunya.com/sandbox-checkout/invoice/test_ABC123", @payment.paydunya_invoice_url
      assert_equal "PAR", @payment.payment_type
    end

    test "should handle invalid masterkey error" do
      stub_request(:post, "https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create")
        .to_return(
          status: 200,
          body: {
            response_code: "1001",
            response_text: "Invalid Masterkey Specified"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = @service.create_checkout_invoice

      assert_not result.success?
      assert_includes result.errors.first, "Configuration PayDunya invalide"
    end

    test "should handle network timeout" do
      stub_request(:post, "https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create")
        .to_timeout

      result = @service.create_checkout_invoice

      assert_not result.success?
      assert_includes result.errors.first, "connexion"
    end

    test "should handle invalid private key error" do
      stub_request(:post, "https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create")
        .to_return(
          status: 200,
          body: {
            response_code: "1002",
            response_text: "Invalid Private Key"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = @service.create_checkout_invoice

      assert_not result.success?
      assert_includes result.errors.first, "Clés API PayDunya invalides"
    end

    test "should build correct invoice payload" do
      payload = @service.send(:build_invoice_payload)

      assert_equal @payment.amount.to_f, payload[:invoice][:total_amount]
      assert_equal "Commande ##{@order.id}", payload[:invoice][:description]
      assert_equal @order.id, payload[:custom_data][:order_id]
      assert_equal @user.id, payload[:custom_data][:user_id]
      assert_equal @payment.id, payload[:custom_data][:payment_id]
    end

    test "should include order items in payload" do
      payload = @service.send(:build_invoice_payload)

      assert_not_nil payload[:invoice][:items]
      assert_not_empty payload[:invoice][:items]
      assert_kind_of Hash, payload[:invoice][:items]
    end

    test "should include delivery fee as tax" do
      # Order fixture already has delivery_fee of 1500
      payload = @service.send(:build_invoice_payload)

      assert_not_nil payload[:invoice][:taxes]
      assert_not_empty payload[:invoice][:taxes]
      # Taxes hash uses string keys, not symbol keys
      assert_not_nil payload[:invoice][:taxes]["tax_0"]
      assert_equal 1500.0, payload[:invoice][:taxes]["tax_0"][:amount]
      assert_equal "Frais de livraison", payload[:invoice][:taxes]["tax_0"][:name]
    end

    test "should include callback urls" do
      payload = @service.send(:build_invoice_payload)

      assert_not_nil payload[:actions][:cancel_url]
      assert_not_nil payload[:actions][:return_url]
      assert_includes payload[:actions][:cancel_url], "/paydunya/cancel"
      assert_includes payload[:actions][:return_url], "/paydunya/success"
    end

    test "should use correct base url for test mode" do
      base_url = @service.instance_variable_get(:@base_url)
      assert_equal "https://app.paydunya.com/sandbox-api/v1", base_url
    end

    test "should use correct base url for live mode" do
      ENV.stubs(:fetch).with("PAYDUNYA_MODE", "test").returns("live")
      ENV.stubs(:fetch).with("PAYDUNYA_MASTER_KEY", "qmR4BzHY-Pxvj-C89u-8B0G-4MdkKeygwCIe").returns("test_master_key")
      ENV.stubs(:fetch).with("PAYDUNYA_PRIVATE_KEY", "test_private_Oswl7zByAb3CcrKwKKl1PChnZ9L").returns("test_private_key")
      ENV.stubs(:fetch).with("PAYDUNYA_TOKEN", "ZIZYuDDbEOvVRYeSbUUp").returns("test_token")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_NAME", "aa").returns("test_store_name")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_TAGLINE", "Votre marketplace en ligne").returns("Votre marketplace en ligne")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_ADDRESS", "Dakar, Sénégal").returns("Dakar, Sénégal")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_PHONE", "+221776857298").returns("+221776857298")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_LOGO", "").returns("")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_URL", "http://localhost:3000").returns("http://localhost:3000")

      service = PaymentServices::PaydunyaHttpService.new(
        payment: @payment,
        order: @order,
        user: @user
      )

      base_url = service.instance_variable_get(:@base_url)
      assert_equal "https://app.paydunya.com/api/v1", base_url
    end

    test "should handle server error response" do
      stub_request(:post, "https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create")
        .to_return(status: 500, body: "Internal Server Error")

      result = @service.create_checkout_invoice

      assert_not result.success?
      assert_not_empty result.errors
    end

    test "should set correct headers" do
      headers = @service.send(:headers)

      assert_equal "application/json", headers["Content-Type"]
      assert_equal "test_master_key", headers["PAYDUNYA-MASTER-KEY"]
      assert_equal "test_private_key", headers["PAYDUNYA-PRIVATE-KEY"]
      assert_equal "test_token", headers["PAYDUNYA-TOKEN"]
    end

    test "should handle missing environment variables gracefully" do
      ENV.stubs(:fetch).with("PAYDUNYA_MASTER_KEY", "qmR4BzHY-Pxvj-C89u-8B0G-4MdkKeygwCIe").returns("")
      ENV.stubs(:fetch).with("PAYDUNYA_PRIVATE_KEY", "test_private_Oswl7zByAb3CcrKwKKl1PChnZ9L").returns("test_private_key")
      ENV.stubs(:fetch).with("PAYDUNYA_TOKEN", "ZIZYuDDbEOvVRYeSbUUp").returns("test_token")
      ENV.stubs(:fetch).with("PAYDUNYA_MODE", "test").returns("test")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_NAME", "aa").returns("test_store_name")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_TAGLINE", "Votre marketplace en ligne").returns("Votre marketplace en ligne")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_ADDRESS", "Dakar, Sénégal").returns("Dakar, Sénégal")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_PHONE", "+221776857298").returns("+221776857298")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_LOGO", "").returns("")
      ENV.stubs(:fetch).with("PAYDUNYA_STORE_URL", "http://localhost:3000").returns("http://localhost:3000")

      service = PaymentServices::PaydunyaHttpService.new(
        payment: @payment,
        order: @order,
        user: @user
      )

      # Le service est créé mais create_checkout_invoice échoue sans clé master
      assert_not_nil service
      stub_request(:post, "https://app.paydunya.com/sandbox-api/v1/checkout-invoice/create").to_return(status: 200, body: { response_code: "1001" }.to_json)
      result = service.create_checkout_invoice
      assert_not result.success?, "create_checkout_invoice doit échouer quand PAYDUNYA_MASTER_KEY est vide"
    end
  end
end
