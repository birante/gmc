require "test_helper"

class ItemAttributeTest < ActiveSupport::TestCase
  setup do
    @item = items(:one)
  end

  test "should create item attribute" do
    attribute = ItemAttribute.new(name: "Couleur", position: 1, item: @item)
    assert attribute.save
    assert_equal "Couleur", attribute.name
  end

  test "should validate presence of name" do
    attribute = ItemAttribute.new(position: 1, item: @item)
    assert_not attribute.valid?
    assert attribute.errors[:name].any?
  end

  test "should validate uniqueness of name within item scope" do
    ItemAttribute.create!(name: "Couleur", position: 1, item: @item)
    duplicate = ItemAttribute.new(name: "Couleur", position: 2, item: @item)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
  end

  test "should allow same name in different items" do
    delivery_category = DeliveryCategory.first || DeliveryCategory.create!(code: "standard", name: "Standard")
    item2 = Item.create!(
      name: "Test Item 2",
      shop: @item.shop,
      product_sub_category: @item.product_sub_category,
      currency: @item.currency,
      delivery_category: delivery_category,
      validation_status: "approved",
      default_price: 1000,
      default_stock_quantity: 10
    )

    attr1 = ItemAttribute.create!(name: "Couleur", position: 1, item: @item)
    attr2 = ItemAttribute.create!(name: "Couleur", position: 1, item: item2)

    assert attr1.valid?
    assert attr2.valid?
  end

  test "should have many attribute values" do
    attribute = @item.item_attributes.create!(name: "Taille", position: 1)
    attribute.attribute_values.create!(value: "S", position: 1)
    attribute.attribute_values.create!(value: "M", position: 2)

    assert_equal 2, attribute.attribute_values.count
  end

  test "should delete attribute values on destroy" do
    attribute = @item.item_attributes.create!(name: "Taille", position: 1)
    attribute.attribute_values.create!(value: "S", position: 1)

    attribute.destroy
    assert_empty AttributeValue.where(item_attribute_id: attribute.id)
  end
end
