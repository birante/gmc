require "test_helper"

class VendorsWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @vendor_attributes = {
      first_name: "Jean",
      last_name: "Dupont",
      phone_number: "0612345678",
      country_code: "+33",
      email: "jean.dupont@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  test "complete vendors workflow: registration -> verification -> dashboard -> shop creation" do
    verification_code = "1234"
    Otp::Generator.stubs(:generate_from_config).returns(verification_code)
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)

    # Étape 1: Accès à la page d'inscription
    get new_vendors_registration_path
    assert_response :success
    assert_select "form"

    # Étape 2: Inscription → crée un PendingRegistration (pas encore de Vendor)
    assert_difference("PendingRegistration.count", 1) do
      post vendors_registration_path, params: { vendor: @vendor_attributes }
    end

    assert_response :redirect
    assert_match(/\/vendors\/verification\/new/, response.location)
    follow_redirect!
    assert_response :success

    # Étape 3: Vérification du code OTP → crée le Vendor
    assert_difference("Vendor.count", 1) do
      post vendors_verification_path, params: {
        otp_code_0: "1",
        otp_code_1: "2",
        otp_code_2: "3",
        otp_code_3: "4"
      }
    end

    vendor = Vendor.find_by(email: @vendor_attributes[:email])
    assert vendor.present?, "Le vendor doit être créé après vérification"

    # Doit rediriger vers la création de boutique (car le vendor n'a pas encore de boutique)
    assert_redirected_to new_vendors_shop_path
    follow_redirect!
    assert_response :success

    # Étape 5: Création d'un shop
    shop_attributes = {
      name: "Ma Boutique Test",
      address: "123 Rue de la Paix, Dakar",
      description: "Description de ma boutique de test",
      legal_info_attributes: {
        rc_number: "DK-2023-B-12345",
        ninea_number: "006123456789"
      },
      contacts_attributes: {
        "0" => {
          phone_number: "771234567",
          country_code: "+221",
          is_whatsapp: "1"
        }
      }
    }

    assert_difference("Shop.count") do
      post vendors_shop_path, params: { shop: shop_attributes, test_vendor_id: vendor.id }
    end

    shop = Shop.find_by(name: "Ma Boutique Test")
    assert shop.present?, "Le shop doit être créé"
    assert_equal vendor, shop.vendor

    # Doit rediriger vers la sélection de plan
    assert_response :redirect
    assert_match /vendors\/plan\/new/, response.location
    follow_redirect!
    assert_response :success

    # Étape 6: Sélectionner un plan
    plan = Plan.find_by(code: "ACCESS") || create(:plan, code: "ACCESS", name: "Access", is_active: true, is_custom: false)
    post vendors_plan_path, params: {
      plan_id: plan.id,
      test_vendor_id: vendor.id
    }
    assert_response :redirect
    assert_match /vendors\/dashboard/, response.location
    follow_redirect!

    # Étape 7: Accès au dashboard avec authentication test parameter
    get vendors_dashboard_path, params: { test_vendor_id: vendor.id, shop_slug: shop.slug }
    assert_response :success

    # Vérifier que le vendor et son shop sont présents
    assert_equal vendor, assigns(:vendor)
    assert_includes assigns(:shops), shop
    assert_equal 1, assigns(:total_shops)
    assert_equal 0, assigns(:active_shops) # Status pending par défaut
    assert_equal 1, assigns(:pending_shops)
  end

  test "should redirect to registration when accessing dashboard without authentication" do
    get vendors_dashboard_path
    assert_redirected_to new_vendors_session_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should handle invalid verification code" do
    Otp::Generator.stubs(:generate_from_config).returns("1234")
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post vendors_registration_path, params: { vendor: @vendor_attributes }
    follow_redirect!

    post vendors_verification_path, params: {
      otp_code_0: "9",
      otp_code_1: "9",
      otp_code_2: "9",
      otp_code_3: "9"
    }

    assert_response :unprocessable_entity
    assert_not_equal new_vendors_shop_path, response.location
  end

  test "should reject registration without email" do
    invalid_attributes = @vendor_attributes.merge(email: "")

    assert_no_difference("PendingRegistration.count") do
      post vendors_registration_path, params: { vendor: invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_nil PendingRegistration.for_vendor.find_by(phone_number: invalid_attributes[:phone_number])
  end

  test "should reject registration with short password" do
    invalid_attributes = @vendor_attributes.merge(password: "1234567", password_confirmation: "1234567")

    assert_no_difference("PendingRegistration.count") do
      post vendors_registration_path, params: { vendor: invalid_attributes }
    end

    assert_response :unprocessable_entity
    assert_nil PendingRegistration.for_vendor.find_by(email: invalid_attributes[:email])
  end

  test "should handle expired verification code" do
    Otp::Generator.stubs(:generate_from_config).returns("1234")
    Otp::Generator.stubs(:ttl_from_config).returns(10.minutes)
    post vendors_registration_path, params: { vendor: @vendor_attributes }
    follow_redirect!
    pending = PendingRegistration.for_vendor.find_by(email: @vendor_attributes[:email])
    pending.update!(otp_expires_at: 1.hour.ago)

    post vendors_verification_path, params: {
      otp_code_0: "1",
      otp_code_1: "2",
      otp_code_2: "3",
      otp_code_3: "4"
    }

    assert_response :unprocessable_entity
    assert_not_equal new_vendors_shop_path, response.location
  end

  test "should handle shop creation without valid vendor" do
    get new_vendors_shop_path
    assert_redirected_to new_vendors_session_path
    assert_equal "You must be logged in to access this page.", flash[:alert]
  end

  test "vendors namespace routes are properly configured" do
    # Vérifier que toutes les routes du namespace vendors fonctionnent
    assert_routing "/vendors/registration/new", controller: "vendors/registrations", action: "new"
    assert_routing({ method: "post", path: "/vendors/registration" },
                   controller: "vendors/registrations", action: "create")

    assert_routing "/vendors/session/new", controller: "vendors/sessions", action: "new"
    assert_routing({ method: "post", path: "/vendors/session" },
                   controller: "vendors/sessions", action: "create")
    assert_routing({ method: "delete", path: "/vendors/session" },
                   controller: "vendors/sessions", action: "destroy")

    assert_routing "/vendors/verification/new", controller: "vendors/verifications", action: "new"
    assert_routing({ method: "post", path: "/vendors/verification" },
                   controller: "vendors/verifications", action: "create")

    assert_routing "/vendors/shop/new", controller: "vendors/shops", action: "new"
    assert_routing({ method: "post", path: "/vendors/shop" },
                   controller: "vendors/shops", action: "create")

    assert_routing "/vendors/dashboard", controller: "vendors/dashboards", action: "show"
  end

  test "vendor can login with phone number and password" do
    vendor = create(:vendor, :verified,
      email: @vendor_attributes[:email],
      password: @vendor_attributes[:password],
      password_confirmation: @vendor_attributes[:password]
    )
    # Create a shop for the vendor so they can access the dashboard
    create(:shop, vendor: vendor)

    # Accès à la page de connexion
    get new_vendors_session_path
    assert_response :success
    assert_select "form"

    # Connexion réussie
    post vendors_session_path, params: {
      phone_number: vendor.phone_number,
      password: @vendor_attributes[:password]
    }

    assert_redirected_to vendors_dashboard_path
    assert_equal vendor.id, session[:vendor_id]
  end

  test "vendor login fails with wrong password" do
    vendor = create(:vendor, :verified,
      email: @vendor_attributes[:email],
      password: @vendor_attributes[:password],
      password_confirmation: @vendor_attributes[:password]
    )

    post vendors_session_path, params: {
      phone_number: vendor.phone_number,
      password: "wrong_password"
    }

    assert_response :unprocessable_entity
    assert_nil session[:vendor_id]
    assert_equal "Incorrect phone number or password", flash[:alert]
  end

  test "vendor can logout" do
    vendor = create(:vendor, :verified,
      email: @vendor_attributes[:email],
      password: @vendor_attributes[:password],
      password_confirmation: @vendor_attributes[:password]
    )

    # Simuler une session
    post vendors_session_path, params: {
      phone_number: vendor.phone_number,
      password: @vendor_attributes[:password]
    }
    assert_equal vendor.id, session[:vendor_id]

    # Déconnexion
    delete vendors_session_path
    assert_redirected_to root_path
    assert_nil session[:vendor_id]
    assert_equal "Successfully signed out", flash[:notice]
  end

  test "upgrade vers un plan custom est bloque et demande un contact" do
    vendor = create(:vendor, :verified)
    shop = create(:shop, :active, vendor: vendor)

    starter = create(:plan,
      code: "STARTER",
      name: "aa Starter",
      is_active: true,
      is_custom: false,
      price: 15000,
      billing_period_months: 3
    )

    partner = create(:plan,
      code: "PARTNER",
      name: "aa Partner",
      is_active: true,
      is_custom: true,
      price: 0,
      billing_period_months: nil
    )

    old_subscription = create(:subscription, shop: shop, plan: starter, status: "active")

    assert_no_difference("Subscription.count") do
      post vendors_plan_path, params: {
        plan_id: partner.id,
        upgrade: true,
        test_vendor_id: vendor.id,
        shop_slug: shop.slug
      }
    end

    assert_response :redirect
    assert_match(/vendors\/plan\/new/, response.location)
    assert_equal I18n.t("vendors.plans.custom_plan_contact_required", phone: Plan.support_contact_phone), flash[:alert]

    old_subscription.reload
    assert_equal "active", old_subscription.status
    assert_equal starter.id, shop.reload.current_subscription.plan_id
  end

  test "upgrade vers un plan payant exige un mode de paiement" do
    vendor = create(:vendor, :verified)
    shop = create(:shop, :active, vendor: vendor)

    access = create(:plan,
      code: "ACCESS",
      name: "aa Access",
      is_active: true,
      is_custom: false,
      price: 0,
      billing_period_months: 1
    )

    business = create(:plan,
      code: "BUSINESS",
      name: "aa Business",
      is_active: true,
      is_custom: false,
      price: 30000,
      billing_period_months: 3
    )

    create(:subscription, shop: shop, plan: access, status: "active")

    post vendors_plan_path, params: {
      plan_id: business.id,
      upgrade: true,
      test_vendor_id: vendor.id,
      shop_slug: shop.slug
    }

    assert_response :redirect
    assert_match(/vendors\/plan\/new/, response.location)
    assert_equal "Veuillez selectionner un mode de paiement.", flash[:alert]
    assert_equal access.id, shop.reload.current_subscription.plan_id
  end
end
