require "test_helper"

class VariantCreationServiceTest < ActiveSupport::TestCase
  parallelize(workers: 1)

  setup do
    @shop = shops(:one)
    @delivery_cat = DeliveryCategory.first || DeliveryCategory.create!(code: "standard", name: "Standard")

    @item = @shop.items.create!(
      name: "Test Item for Variants",
      product_sub_category: ProductSubCategory.first,
      currency: Currency.first,
      delivery_category: @delivery_cat,
      validation_status: "approved",
      default_price: 1000,
      default_stock_quantity: 50
    )

    # Créer des attributs
    @color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    @red_value = @color_attr.attribute_values.create!(value: "Rouge", position: 1)
    @blue_value = @color_attr.attribute_values.create!(value: "Bleu", position: 2)

    @size_attr = @item.item_attributes.create!(name: "Taille", position: 2)
    @s_value = @size_attr.attribute_values.create!(value: "S", position: 1)
    @m_value = @size_attr.attribute_values.create!(value: "M", position: 2)

    @service = VariantCreationService.new(@item)
  end

  test "should process variants with combination_data" do
    variants_data = [
      {
        "price" => "1200",
        "stock_quantity" => "30",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Rouge" }.to_json,
          { "name" => "Taille", "value" => "S" }.to_json
        ]
      },
      {
        "price" => "1300",
        "stock_quantity" => "25",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Bleu" }.to_json,
          { "name" => "Taille", "value" => "M" }.to_json
        ]
      }
    ]

    initial_count = @item.variants.count
    @service.process_variants_with_attributes(variants_data)

    assert_equal initial_count + 2, @item.variants.count
  end

  test "should associate correct attribute values to variant" do
    variants_data = [
      {
        "price" => "1200",
        "stock_quantity" => "30",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Rouge" }.to_json,
          { "name" => "Taille", "value" => "S" }.to_json
        ]
      }
    ]

    @service.process_variants_with_attributes(variants_data)

    variant = @item.variants.where(is_default: false).last
    assert_equal 2, variant.attribute_values.count

    # Vérifier que les valeurs correctes sont associées
    color_value = variant.attribute_values.joins(:item_attribute)
                        .where(item_attributes: { name: "Couleur" }).first
    assert_equal "Rouge", color_value.value

    size_value = variant.attribute_values.joins(:item_attribute)
                       .where(item_attributes: { name: "Taille" }).first
    assert_equal "S", size_value.value
  end

  test "should generate unique SKU for each variant" do
    variants_data = [
      {
        "price" => "1200",
        "stock_quantity" => "30",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Rouge" }.to_json,
          { "name" => "Taille", "value" => "S" }.to_json
        ]
      },
      {
        "price" => "1300",
        "stock_quantity" => "25",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Rouge" }.to_json,
          { "name" => "Taille", "value" => "M" }.to_json
        ]
      }
    ]

    @service.process_variants_with_attributes(variants_data)

    variants = @item.variants.where(is_default: false).last(2)
    assert_equal 2, variants.count, "Should have created 2 variants"
    assert variants[0].sku.present?, "First variant should have a SKU"
    assert variants[1].sku.present?, "Second variant should have a SKU"
    assert_not_equal variants[0].sku, variants[1].sku, "SKUs should be unique"
  end

  test "should handle missing attribute values gracefully" do
    variants_data = [
      {
        "price" => "1200",
        "stock_quantity" => "30",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Inexistant" }.to_json,
          { "name" => "Taille", "value" => "S" }.to_json
        ]
      }
    ]

    # Ne devrait pas lever d'erreur
    assert_nothing_raised do
      @service.process_variants_with_attributes(variants_data)
    end
  end

  test "should set correct price and stock for variant" do
    variants_data = [
      {
        "price" => "2500",
        "stock_quantity" => "75",
        "combination_data" => [
          { "name" => "Couleur", "value" => "Rouge" }.to_json
        ]
      }
    ]

    @service.process_variants_with_attributes(variants_data)

    variant = @item.variants.where(is_default: false).last
    assert_equal 2500, variant.price
    assert_equal 75, variant.stock_quantity
  end
end
