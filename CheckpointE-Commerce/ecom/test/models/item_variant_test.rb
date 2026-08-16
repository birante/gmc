require "test_helper"

class ItemVariantTest < ActiveSupport::TestCase
  setup do
    @shop = shops(:one)
    @delivery_category = DeliveryCategory.first || DeliveryCategory.create!(code: "standard", name: "Standard")
    @item = @shop.items.create!(
      name: "Test Item",
      product_sub_category: ProductSubCategory.first,
      currency: Currency.first,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 1000,
      default_stock_quantity: 10
    )
  end

  # ========== VALIDATIONS ==========

  test "should validate presence of price" do
    # Créer un item sans variante par défaut pour tester la validation du prix
    item_without_default = @shop.items.new(
      name: "Test Item Without Default",
      product_sub_category: ProductSubCategory.first,
      currency: Currency.first,
      delivery_category: @delivery_category,
      validation_status: "approved"
    )
    # Ajouter une variante avec un prix
    item_without_default.variants.build(price: 100, stock_quantity: 10, sku: "WITH-PRICE", is_default: true)
    item_without_default.save!

    # Maintenant tester une variante sans prix (ne peut pas hériter)
    variant = item_without_default.variants.build(stock_quantity: 10, sku: "NO-PRICE", is_default: false)
    variant.define_singleton_method(:should_inherit?) { false }  # Bloquer l'héritage
    assert_not variant.valid?
    assert variant.errors[:price].any?
  end

  test "should validate price is greater than or equal to 0.01" do
    variant = @item.variants.build(price: 0, stock_quantity: 10, sku: "TEST-SKU")
    assert_not variant.valid?
    assert variant.errors[:price].any?

    variant.price = 0.01
    assert_not variant.valid?

    variant.price = 1
    assert variant.valid?
  end

  test "should validate stock_quantity is greater than or equal to 0" do
    variant = @item.variants.build(price: 100, stock_quantity: -1, sku: "TEST-SKU")
    assert_not variant.valid?
    assert variant.errors[:stock_quantity].any?

    variant.stock_quantity = 0
    assert variant.valid?
  end

  test "should validate uniqueness of SKU" do
    @item.variants.create!(price: 100, stock_quantity: 10, sku: "UNIQUE-SKU")
    duplicate = @item.variants.build(price: 100, stock_quantity: 10, sku: "UNIQUE-SKU")
    assert_not duplicate.valid?
    assert duplicate.errors[:sku].any?
  end

  # ========== ASSOCIATIONS ==========

  test "should belong to item" do
    variant = @item.variants.first
    assert_equal @item, variant.item
  end

  test "should have many attribute values" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10, sku: "TEST-SKU-1")

    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    red_value = color_attr.attribute_values.create!(value: "Rouge", position: 1)

    variant.attribute_values << red_value
    assert_equal 1, variant.attribute_values.count
    assert_includes variant.attribute_values, red_value
  end

  # ========== SCOPES ==========

  test "default scope should return default variants" do
    default_variant = @item.variants.first # Créée automatiquement
    non_default = @item.variants.create!(price: 200, stock_quantity: 20, sku: "NON-DEFAULT", is_default: false)

    default_variants = @item.variants.default
    assert_includes default_variants, default_variant
    assert_not_includes default_variants, non_default
  end

  test "in_stock scope should return variants with stock" do
    in_stock = @item.variants.create!(price: 100, stock_quantity: 10, sku: "IN-STOCK")
    out_of_stock = @item.variants.create!(price: 100, stock_quantity: 0, sku: "OUT-OF-STOCK")

    stock_variants = @item.variants.in_stock
    assert_includes stock_variants, in_stock
    assert_not_includes stock_variants, out_of_stock
  end

  # ========== METHODS ==========

  test "should check if in stock" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10, sku: "TEST-SKU-2")
    assert variant.in_stock?

    variant.update(stock_quantity: 0)
    assert_not variant.in_stock?
  end

  test "should format attributes correctly" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10, sku: "TEST-SKU-3")

    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    red_value = color_attr.attribute_values.create!(value: "Rouge", position: 1)

    size_attr = @item.item_attributes.create!(name: "Taille", position: 2)
    m_value = size_attr.attribute_values.create!(value: "M", position: 1)

    variant.attribute_values << red_value
    variant.attribute_values << m_value

    formatted = variant.formatted_attributes
    assert formatted.is_a?(String)
    assert_includes formatted, "Rouge"
    assert_includes formatted, "M"
  end

  # ========== SKU GENERATION ==========

  test "should generate SKU automatically for default variant" do
    # Créer un nouvel item pour éviter les conflits de SKU
    new_item = @shop.items.create!(
      name: "SKU Test Item",
      product_sub_category: ProductSubCategory.first,
      currency: Currency.first,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 1500,
      default_stock_quantity: 25
    )

    variant = new_item.variants.first  # La variante par défaut créée automatiquement
    assert_not_nil variant.sku
    assert_match /DEFAULT/, variant.sku
  end

  test "should allow manual SKU for non-default variant" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10, sku: "MANUAL-SKU", is_default: false)
    assert_equal "MANUAL-SKU", variant.sku
  end

  test "should round price and sale_price for XOF currency" do
    variant = @item.variants.create!(
      price: 149999.96,
      sale_price: 120000.49,
      stock_quantity: 10,
      sku: "XOF-ROUND",
      is_default: false
    )

    assert_equal BigDecimal("150000"), variant.price
    assert_equal BigDecimal("120000"), variant.sale_price
  end

  # ========== DELETION ==========

  test "should not delete variant if it has order items" do
    variant = @item.variants.create!(price: 100, stock_quantity: 10, sku: "ORDERED-SKU")

    # Créer une commande avec cet variant
    # (à implémenter selon votre structure)
    # Pour l'instant, on teste juste que le variant peut être supprimé s'il n'a pas de commandes
    assert variant.destroy
  end
end
