require "test_helper"

class VendorTest < ActiveSupport::TestCase
  def setup
    @vendor = build(:vendor)
  end

  # Tests de validation
  test "should be valid with valid attributes" do
    assert @vendor.valid?
  end

  test "should require first_name" do
    @vendor.first_name = nil
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:first_name], "can't be blank"
  end

  test "should require last_name" do
    @vendor.last_name = nil
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:last_name], "can't be blank"
  end

  test "should require phone_number" do
    @vendor.phone_number = nil
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:phone_number], "can't be blank"
  end

  test "should require country_code" do
    @vendor.country_code = nil
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:country_code], "can't be blank"
  end

  test "should require email" do
    @vendor.email = nil
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:email], "can't be blank"
  end

  test "should require unique phone_number" do
    vendor1 = create(:vendor)
    vendor2 = build(:vendor, phone_number: vendor1.phone_number)
    assert_not vendor2.valid?
    assert_includes vendor2.errors[:phone_number], "has already been taken"
  end

  test "should require unique email" do
    vendor1 = create(:vendor, email: "test@example.com")
    vendor2 = build(:vendor, email: "test@example.com")
    assert_not vendor2.valid?
    assert_includes vendor2.errors[:email], "has already been taken"
  end

  test "should validate email format" do
    @vendor.email = "invalid_email"
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:email], "is invalid"
  end

  test "should validate password length when provided" do
    @vendor.password = "1234567"
    @vendor.password_confirmation = "1234567"
    assert_not @vendor.valid?
    assert_includes @vendor.errors[:password], "is too short (minimum is 8 characters)"
  end

  # Tests de normalisation
  test "should normalize email to lowercase" do
    @vendor.email = "TEST@EXAMPLE.COM"
    @vendor.save
    assert_equal "test@example.com", @vendor.email
  end

  test "should strip and normalize phone_number" do
    @vendor.phone_number = " 77 123 45 67 "
    @vendor.save
    assert_equal "771234567", @vendor.phone_number
  end

  # Tests des relations
  test "should have many shops" do
    vendor = create(:vendor)
    shop1 = create(:shop, vendor: vendor)
    shop2 = create(:shop, vendor: vendor)

    assert_includes vendor.shops, shop1
    assert_includes vendor.shops, shop2
    assert_equal 2, vendor.shops.count
  end

  test "should destroy associated shops when vendor is destroyed" do
    vendor = create(:vendor)
    shop = create(:shop, vendor: vendor)
    shop_id = shop.id

    vendor.destroy
    assert_nil Shop.find_by(id: shop_id)
  end

  # Tests des ransackable attributes
  test "should include correct ransackable attributes" do
    expected_attributes = [ "created_at", "email", "first_name", "id", "last_name",
                          "phone_number", "country_code", "updated_at", "status" ]

    assert_equal expected_attributes.sort, Vendor.ransackable_attributes.sort
  end

  test "should include correct ransackable associations" do
    expected_associations = [ "shops" ]

    assert_equal expected_associations.sort, Vendor.ransackable_associations.sort
  end
end
