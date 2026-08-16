require "test_helper"

class ProductAttributeTest < ActiveSupport::TestCase
  # ========== VALIDATIONS ==========

  test "should validate presence of name" do
    attribute = ProductAttribute.new(is_active: true)
    assert_not attribute.valid?
    assert attribute.errors[:name].any?
  end

  test "should validate uniqueness of name" do
    ProductAttribute.create!(name: "Couleur", is_active: true)
    duplicate = ProductAttribute.new(name: "Couleur", is_active: true)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "should allow case-insensitive uniqueness" do
    ProductAttribute.create!(name: "Couleur", is_active: true)
    duplicate = ProductAttribute.new(name: "couleur", is_active: true)
    assert_not duplicate.valid?
  end

  # ========== ASSOCIATIONS ==========

  test "should have many product_attribute_values" do
    attribute = ProductAttribute.create!(name: "Taille", is_active: true)
    attribute.product_attribute_values.create!(value: "S", is_active: true)
    attribute.product_attribute_values.create!(value: "M", is_active: true)

    assert_equal 2, attribute.product_attribute_values.count
  end

  test "should delete attribute values on destroy" do
    attribute = ProductAttribute.create!(name: "Matière", is_active: true)
    attribute.product_attribute_values.create!(value: "Coton", is_active: true)

    attribute.destroy
    assert_empty ProductAttributeValue.where(product_attribute_id: attribute.id)
  end

  test "should accept nested attributes for values" do
    attribute = ProductAttribute.new(
      name: "Pointure",
      is_active: true,
      product_attribute_values_attributes: [
        { value: "38", is_active: true },
        { value: "39", is_active: true },
        { value: "40", is_active: true }
      ]
    )

    assert attribute.save
    assert_equal 3, attribute.product_attribute_values.count
  end

  # ========== SCOPES ==========

  test "active scope should return only active attributes" do
    active = ProductAttribute.create!(name: "Couleur Active", is_active: true)
    inactive = ProductAttribute.create!(name: "Couleur Inactive", is_active: false)

    active_attributes = ProductAttribute.active
    assert_includes active_attributes, active
    assert_not_includes active_attributes, inactive
  end

  test "ordered scope should order by name" do
    ProductAttribute.create!(name: "Zebra", is_active: true)
    ProductAttribute.create!(name: "Alpha", is_active: true)
    ProductAttribute.create!(name: "Bravo", is_active: true)

    ordered = ProductAttribute.ordered
    assert_equal "Alpha", ordered.first.name
    assert_equal "Zebra", ordered.last.name
  end

  # ========== METHODS ==========

  test "should return active values only" do
    attribute = ProductAttribute.create!(name: "Taille", is_active: true)
    active_value = attribute.product_attribute_values.create!(value: "S", is_active: true)
    inactive_value = attribute.product_attribute_values.create!(value: "XXL", is_active: false)

    active_values = attribute.product_attribute_values.where(is_active: true)
    assert_includes active_values, active_value
    assert_not_includes active_values, inactive_value
  end
end
