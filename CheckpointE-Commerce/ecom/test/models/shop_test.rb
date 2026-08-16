require "test_helper"

class ShopTest < ActiveSupport::TestCase
  def setup
    @vendor = create(:vendor)
    @shop = build(:shop, vendor: @vendor)
  end

  # Tests de validation
  test "should be valid with valid attributes" do
    assert @shop.valid?
  end

  test "should require name" do
    @shop.name = nil
    assert_not @shop.valid?
    assert_includes @shop.errors[:name], "can't be blank"
  end

  test "should require unique name" do
    shop1 = create(:shop, name: "Test Shop")
    shop2 = build(:shop, name: "Test Shop")
    assert_not shop2.valid?
    assert_includes shop2.errors[:name], "has already been taken"
  end


  test "should belong to vendor" do
    @shop.vendor = nil
    assert_not @shop.valid?
  end

  # Tests des relations
  test "should belong a vendor" do
    assert_equal @vendor, @shop.vendor
  end

  test "should have many social links" do
    @shop.save!
    link1 = create(:shop_social_link, shop: @shop)
    link2 = create(:shop_social_link, shop: @shop)

    assert_includes @shop.social_links, link1
    assert_includes @shop.social_links, link2
    assert_equal 2, @shop.social_links.count
  end


  test "should have one legal info" do
    @shop.save!
    legal_info = create(:shop_legal_info, shop: @shop)

    assert_equal legal_info, @shop.legal_info
  end

  test "should destroy associated records when shop is destroyed" do
    @shop.save!
    contact = create(:shop_contact, shop: @shop)
    social_link = create(:shop_social_link, shop: @shop)
    legal_info = create(:shop_legal_info, shop: @shop)

    contact_id = contact.id
    social_link_id = social_link.id
    legal_info_id = legal_info.id

    @shop.destroy

    assert_nil ShopContact.find_by(id: contact_id)
    assert_nil ShopSocialLink.find_by(id: social_link_id)
    assert_nil ShopLegalInfo.find_by(id: legal_info_id)
  end

  # Tests des enums
  test "should have correct status enum values" do
    expected_statuses = %w[pending active suspended deactivate]
    assert_equal expected_statuses, Shop::STATUSES
  end

  test "should set pending status by default" do
    shop = Shop.new(name: "Test Shop", vendor: @vendor)
    shop.valid? # Trigger validations
    assert_equal "pending", shop.status
  end

  test "should allow all valid statuses" do
    Shop::STATUSES.each do |status|
      @shop.status = status
      assert @shop.valid?, "Should be valid with status '#{status}'"
    end
  end

  # Tests des callbacks
  test "should generate shop code before create" do
    @shop.save!
    assert_not_nil @shop.code
    assert @shop.code.start_with?("SHOP")
    assert_equal 10, @shop.code.length # SHOP + 6 hex chars
  end

  test "should generate unique shop codes" do
    shop1 = create(:shop)
    shop2 = create(:shop)

    assert_not_equal shop1.code, shop2.code
  end

  test "should set default social links before create" do
    # Créer quelques plateformes sociales actives
    facebook = create(:social_platform, :facebook, is_active: true, position: 1)
    instagram = create(:social_platform, :instagram, is_active: true, position: 2)
    inactive_platform = create(:social_platform, is_active: false)

    @shop.save!

    assert_equal 2, @shop.social_links.count
    platform_names = @shop.social_links.map { |link| link.social_platform.name }
    assert_includes platform_names, "Facebook"
    assert_includes platform_names, "Instagram"
    assert_not_includes platform_names, inactive_platform.name
  end

  test "should set default contacts before create" do
    @shop.save!

    assert_equal 1, @shop.contacts.count
    contact = @shop.contacts.first
    assert_equal "221", contact.country_code
    assert_equal "", contact.phone_number
    assert_equal false, contact.is_whatsapp
  end


  # Tests des ransackable attributes
  test "should include correct ransackable attributes" do
    expected_attributes = [ "code", "created_at", "id", "name", "slug", "status",
                          "updated_at", "vendor_id", "address", "description",
                          "primary_color", "secondary_color", "shop_type" ]

    assert_equal expected_attributes.sort, Shop.ransackable_attributes.sort
  end

  test "should include correct ransackable associations" do
    expected_associations = [ "vendor", "legal_info", "social_links", "contacts", "sectors", "items" ]

    assert_equal expected_associations.sort, Shop.ransackable_associations.sort
  end

  # Tests des scopes
  test "should filter by status using enum scopes" do
    pending_shop = create(:shop, status: "pending")
    active_shop = create(:shop, :active)

    pending_shops = Shop.pending
    active_shops = Shop.active

    assert_includes pending_shops, pending_shop
    assert_not_includes pending_shops, active_shop

    assert_includes active_shops, active_shop
    assert_not_includes active_shops, pending_shop
  end
end
