require "test_helper"

class ItemTest < ActiveSupport::TestCase
  setup do
    @shop = shops(:one)
    @delivery_category = DeliveryCategory.first || DeliveryCategory.create!(code: "standard", name: "Standard")
    @currency = Currency.first || Currency.create!(code: "XOF", symbol: "F CFA", is_active: true)
    @sub_category = ProductSubCategory.first || ProductSubCategory.create!(
      name: "Test Category",
      product_category: ProductCategory.first || ProductCategory.create!(name: "Test", is_active: true),
      is_active: true
    )
  end

  # ========== VALIDATIONS ==========

  test "should validate presence of name" do
    item = Item.new(
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      default_price: 1000,
      default_stock_quantity: 10
    )
    assert_not item.valid?
    assert item.errors[:name].any?
  end

  test "should validate validation_status inclusion" do
    item = Item.new(
      name: "Test Item",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      validation_status: "invalid_status",
      default_price: 1000,
      default_stock_quantity: 10
    )
    assert_not item.valid?
    assert item.errors[:validation_status].any?
  end

  test "should require delivery_category when approved" do
    item = Item.new(
      name: "Test Item",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      validation_status: "approved",
      delivery_category: nil,
      default_price: 1000,
      default_stock_quantity: 10
    )
    assert_not item.valid?
    assert item.errors[:delivery_category].any?
  end

  # ========== FRIENDLY_ID ==========

  test "should generate slug from name" do
    item = Item.create!(
      name: "Ballon de Football",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 5000,
      default_stock_quantity: 20
    )
    assert_not_nil item.slug
    assert_equal "ballon-de-football", item.slug
  end

  test "should find item by slug" do
    item = Item.create!(
      name: "T-Shirt Rouge",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 3000,
      default_stock_quantity: 15
    )
    found = Item.friendly.find(item.slug)
    assert_equal item.id, found.id
  end

  # ========== DEFAULT VARIANT CREATION ==========

  test "should create default variant on item creation" do
    item = Item.create!(
      name: "Test Product",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 2000,
      default_stock_quantity: 30
    )

    assert_equal 1, item.variants.count
    default_variant = item.default_variant
    assert_not_nil default_variant
    assert default_variant.is_default?
    assert_equal 2000, default_variant.price
    assert_equal 30, default_variant.stock_quantity
  end

  test "should not create default variant if variants already exist" do
    item = Item.new(
      name: "Test Product",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 2000,
      default_stock_quantity: 30
    )

    # Ajouter une variante manuellement avant de sauvegarder
    item.variants.build(price: 1500, stock_quantity: 25, sku: "MANUAL-SKU", is_default: true)
    item.save!

    assert_equal 1, item.variants.count
  end

  # ========== VARIANT GENERATION ==========

  test "should generate variants from attributes" do
    item = Item.create!(
      name: "Test Product",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 2000,
      default_stock_quantity: 30
    )

    # Créer des attributs
    color_attr = item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)
    color_attr.attribute_values.create!(value: "Bleu", position: 2)

    size_attr = item.item_attributes.create!(name: "Taille", position: 2)
    size_attr.attribute_values.create!(value: "S", position: 1)
    size_attr.attribute_values.create!(value: "M", position: 2)

    # Générer les variantes
    generated = item.generate_variants!(2000, 30)

    assert_equal 4, generated.count # 2 couleurs * 2 tailles
    assert_equal 5, item.variants.count # 4 générées + 1 par défaut
  end

  test "should calculate variant combinations count" do
    item = Item.create!(
      name: "Test Product",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 2000,
      default_stock_quantity: 30
    )

    color_attr = item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)
    color_attr.attribute_values.create!(value: "Bleu", position: 2)
    color_attr.attribute_values.create!(value: "Vert", position: 3)

    size_attr = item.item_attributes.create!(name: "Taille", position: 2)
    size_attr.attribute_values.create!(value: "S", position: 1)
    size_attr.attribute_values.create!(value: "M", position: 2)

    assert_equal 6, item.variant_combinations_count # 3 * 2
  end

  # ========== SCOPES ==========

  test "available_for_sale scope should return only approved items" do
    approved_item = Item.create!(
      name: "Approved Item",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 1000,
      default_stock_quantity: 10
    )

    pending_item = Item.create!(
      name: "Pending Item",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      validation_status: "pending",
      default_price: 1000,
      default_stock_quantity: 10
    )

    available_items = Item.available_for_sale
    assert_includes available_items, approved_item
    assert_not_includes available_items, pending_item
  end

  # ========== ANALYTICS ==========

  test "should increment view count" do
    item = Item.create!(
      name: "Test Product",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 2000,
      default_stock_quantity: 30
    )

    initial_count = item.views_count || 0
    item.increment_view_count
    assert_equal initial_count + 1, item.views_count
  end

  test "should return analytics summary" do
    item = Item.create!(
      name: "Test Product",
      shop: @shop,
      product_sub_category: @sub_category,
      currency: @currency,
      delivery_category: @delivery_category,
      validation_status: "approved",
      default_price: 2000,
      default_stock_quantity: 30
    )

    summary = item.analytics_summary
    assert_not_nil summary
    assert_includes summary.keys, :total_views
    assert_includes summary.keys, :recent_views
    assert_includes summary.keys, :unique_visitors
  end
end
