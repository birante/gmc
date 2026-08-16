require "test_helper"

class AttributeValueTest < ActiveSupport::TestCase
  setup do
    @item = items(:one)
    @attribute = @item.item_attributes.create!(name: "Couleur", position: 1)
  end

  test "should create attribute value" do
    value = AttributeValue.new(value: "Rouge", position: 1, item_attribute: @attribute)
    assert value.save
    assert_equal "Rouge", value.value
  end

  test "should validate presence of value" do
    value = AttributeValue.new(position: 1, item_attribute: @attribute)
    assert_not value.valid?
    assert value.errors[:value].any?
  end

  test "should validate uniqueness of value within attribute scope" do
    AttributeValue.create!(value: "Rouge", position: 1, item_attribute: @attribute)
    duplicate = AttributeValue.new(value: "Rouge", position: 2, item_attribute: @attribute)
    assert_not duplicate.valid?
    assert duplicate.errors[:value].any?
  end

  test "should allow same value in different attributes" do
    attribute2 = @item.item_attributes.create!(name: "Taille", position: 2)

    value1 = AttributeValue.create!(value: "M", position: 1, item_attribute: @attribute)
    value2 = AttributeValue.create!(value: "M", position: 1, item_attribute: attribute2)

    assert value1.valid?
    assert value2.valid?
  end

  test "should have many variants through variant attribute values" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10)
    value = @attribute.attribute_values.create!(value: "Bleu", position: 1)

    variant.variant_attribute_values.create!(attribute_value: value)

    assert value.variants.include?(variant)
  end

  test "should destroy variant attribute values on destroy" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10)
    value = @attribute.attribute_values.create!(value: "Bleu", position: 1)
    variant.variant_attribute_values.create!(attribute_value: value)

    value.destroy
    assert_empty VariantAttributeValue.where(attribute_value_id: value.id)
  end
end
