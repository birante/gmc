require "test_helper"

class ShopContactTest < ActiveSupport::TestCase
  def setup
    @shop = create(:shop)
    @contact = build(:shop_contact, shop: @shop)
  end

  # Tests de validation
  test "should be valid with valid attributes" do
    assert @contact.valid?
  end

  test "should require a shop association" do
    @contact.shop = nil
    assert_not @contact.valid?
  end

  # Tests des relations
  test "should have a valid shop association" do
    assert_equal @shop, @contact.shop
  end

  # Tests des callbacks
  test "should set default country code before create" do
    contact = ShopContact.new(shop: @shop)
    contact.valid? # Trigger validations and callbacks
    assert_equal "221", contact.country_code
  end

  test "should not override existing country code" do
    contact = ShopContact.new(shop: @shop, country_code: "33")
    contact.valid?
    assert_equal "33", contact.country_code
  end

  # Tests des ransackable attributes
  test "should include correct ransackable attributes" do
    expected_attributes = [ "country_code", "created_at", "id", "is_whatsapp",
                          "phone_number", "shop_id", "updated_at" ]

    assert_equal expected_attributes.sort, ShopContact.ransackable_attributes.sort
  end

  test "should include correct ransackable associations" do
    expected_associations = [ "shop" ]

    assert_equal expected_associations.sort, ShopContact.ransackable_associations.sort
  end

  # Tests des traits
  test "should create whatsapp contact" do
    whatsapp_contact = create(:shop_contact, :with_whatsapp)
    assert whatsapp_contact.is_whatsapp
  end

  test "should create contact with different country" do
    contact = create(:shop_contact, :with_different_country)
    assert_equal "33", contact.country_code
    assert_equal "123456789", contact.phone_number
  end
end
