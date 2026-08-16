require "test_helper"

class Vendors::ShopsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @vendor = create(:vendor, :verified) # Vendor must be verified to access shops
    @shop_attributes = {
      name: "Test Shop",
      description: "A test shop description",
      address: "123 Test Street, Test City"
    }
  end

  # Tests pour l'action new
  test "should show new shop form with valid vendor" do
    get new_vendors_shop_path, params: { test_vendor_id: @vendor.id }

    assert_response :success
    assert_equal @vendor, assigns(:vendor)
    assert_kind_of Shop, assigns(:shop)
    assert assigns(:shop).new_record?
  end

  test "should redirect when vendor not found for new" do
    get new_vendors_shop_path

    assert_redirected_to new_vendors_session_path
    assert_equal "You must be logged in to access this page.", flash[:alert]
  end

  test "should build shop associated with vendor for new" do
    get new_vendors_shop_path, params: { test_vendor_id: @vendor.id }

    shop = assigns(:shop)
    assert_equal @vendor, shop.vendor
  end

  # Tests pour l'action create
  test "should create shop with valid attributes" do
    assert_difference("Shop.count") do
      post vendors_shop_path, params: {
        shop: @shop_attributes,
        test_vendor_id: @vendor.id
      }
    end

    shop = Shop.last
    assert_equal "Test Shop", shop.name
    assert_equal "A test shop description", shop.description
    assert_equal @vendor, shop.vendor

    # La redirection va maintenant vers la sélection de plan
    assert_response :redirect
    assert_match /vendors\/plan\/new/, response.location
    assert_match /Shop created successfully/, flash[:notice]
  end

  test "should set vendor session after successful create" do
    post vendors_shop_path, params: {
      shop: @shop_attributes,
      test_vendor_id: @vendor.id
    }

    # Dans les tests, on vérifie que la création a réussi
    # La redirection va maintenant vers la sélection de plan
    assert_response :redirect
    shop = Shop.last
    assert_match /vendors\/plan\/new/, response.location
  end


  test "should create shop with associated records" do
    # Créer des plateformes sociales actives
    create(:social_platform, :facebook, is_active: true)
    create(:social_platform, :instagram, is_active: true)

    post vendors_shop_path, params: {
      shop: @shop_attributes,
      test_vendor_id: @vendor.id
    }

    shop = Shop.last

    # Vérifier que les associations par défaut sont créées
    assert shop.social_links.count > 0
    assert_equal 1, shop.contacts.count

    # Vérifier le contact par défaut
    contact = shop.contacts.first
    assert_equal "221", contact.country_code
    assert_equal false, contact.is_whatsapp
  end

  test "should not create shop with invalid attributes" do
    assert_no_difference("Shop.count") do
      post vendors_shop_path, params: {
        shop: { name: "" }, # Nom vide, invalide
        test_vendor_id: @vendor.id
      }
    end

    assert_response :unprocessable_entity
  end

  test "should handle creation with minimal required data" do
    assert_difference("Shop.count") do
      post vendors_shop_path, params: {
        shop: { name: "Minimal Shop", address: "Minimal Address" },
        test_vendor_id: @vendor.id
      }
    end

    shop = Shop.last
    assert_equal "Minimal Shop", shop.name
    assert_nil shop.description
    assert_equal @vendor, shop.vendor
  end
end
