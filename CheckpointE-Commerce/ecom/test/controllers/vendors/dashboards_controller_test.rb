require "test_helper"

class Vendors::DashboardsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::Assertions

  private

  def authenticate_vendor(vendor)
    @authenticated_vendor = vendor
  end

  def get_authenticated(path)
    get path, params: { test_vendor_id: @authenticated_vendor&.id }
  end
  def setup
    @vendor = create(:vendor, :verified) # Vendor must be verified to access dashboard
    @plan = create(:plan, code: "ACCESS", name: "Access")
    @shop = create(:shop, :complete, vendor: @vendor)
    create(:subscription, shop: @shop, plan: @plan)
  end

  test "should redirect to registration when no vendor is authenticated" do
    get vendors_dashboard_path
    assert_redirected_to new_vendors_session_path
    assert_equal "You must be logged in to access this page", flash[:alert]
  end

  test "should show dashboard when vendor is authenticated" do
    # Simuler une session vendor authentifiée
    authenticate_vendor(@vendor)
    get_authenticated vendors_dashboard_path
    assert_response :success

    # Vérifier que les variables d'instance sont assignées
    assert_equal @vendor, assigns(:vendor)
    assert_includes assigns(:shops), @shop
    assert_equal 1, assigns(:total_shops)
    assert_equal 0, assigns(:active_shops) # Le shop est en status pending par défaut
    assert_equal 1, assigns(:pending_shops)
    assert_equal 0, assigns(:total_items)
  end

  test "should avoid unnecessary eager loading on shops" do
    authenticate_vendor(@vendor)
    get_authenticated vendors_dashboard_path

    # Le dashboard ne doit pas précharger des associations lourdes non utilisées.
    shop = assigns(:shops).first
    refute shop.association(:legal_info).loaded?
    refute shop.association(:contacts).loaded?
    refute shop.association(:social_links).loaded?
    refute shop.association(:sectors).loaded?
    refute shop.association(:items).loaded?
  end

  test "should order shops by created_at desc" do
    # Créer un second shop plus récent avec subscription
    newer_shop = create(:shop, vendor: @vendor)
    create(:subscription, shop: newer_shop, plan: @plan)

    authenticate_vendor(@vendor)
    get_authenticated vendors_dashboard_path

    shops = assigns(:shops)
    assert_equal newer_shop, shops.first
    assert_equal @shop, shops.last
  end

  test "should calculate correct statistics" do
    # Créer différents types de shops avec subscriptions
    active_shop = create(:shop, :active, vendor: @vendor)
    create(:subscription, shop: active_shop, plan: @plan)
    suspended_shop = create(:shop, :suspended, vendor: @vendor)
    create(:subscription, shop: suspended_shop, plan: @plan)

    authenticate_vendor(@vendor)
    get_authenticated vendors_dashboard_path

    assert_equal 3, assigns(:total_shops) # pending + active + suspended
    assert_equal 1, assigns(:active_shops)
    assert_equal 1, assigns(:pending_shops)
    assert_equal 0, assigns(:total_items) # No items since Item model doesn't exist yet
    assert_not_nil assigns(:stats)
  end

  test "should handle vendor with no shops" do
    vendor_without_shops = create(:vendor, :verified) # Vendor must be verified

    authenticate_vendor(vendor_without_shops)
    get_authenticated vendors_dashboard_path

    # Vendor without shops should be redirected to shop creation
    assert_redirected_to new_vendors_shop_path
  end

  test "current_vendor should return vendor when session exists" do
    authenticate_vendor(@vendor)
    get_authenticated vendors_dashboard_path

    # La méthode current_vendor est private, on teste via son effet
    assert_equal @vendor, assigns(:vendor)
  end

  test "current_vendor should return nil when session doesn't exist" do
    # Ne pas définir session[:vendor_id]

    get vendors_dashboard_path

    assert_redirected_to new_vendors_session_path
  end

  test "current_vendor should return nil when vendor doesn't exist" do
    get vendors_dashboard_path, params: { test_vendor_id: 99999 } # ID qui n'existe pas

    assert_redirected_to new_vendors_session_path
  end
end
