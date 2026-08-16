require "test_helper"

class VariantGeneratorServiceTest < ActiveSupport::TestCase
  # Disable parallel execution to avoid SKU uniqueness conflicts
  parallelize(workers: 1)

  setup do
    @shop = shops(:one)
    @delivery_cat = DeliveryCategory.first || DeliveryCategory.create!(code: "standard", name: "Standard")

    @item = @shop.items.create!(
      name: "Test Item",
      product_sub_category: ProductSubCategory.first,
      currency: Currency.first,
      delivery_category: @delivery_cat,
      validation_status: "approved",
      default_price: 1000,
      default_stock_quantity: 50
    )

    @service = VariantGeneratorService.new(@item)
  end

  test "should return empty combinations when no attributes" do
    combinations = @service.generate_combinations
    assert_empty combinations
  end

  test "should generate correct number of combinations" do
    # Créer 2 attributs avec 2 et 3 valeurs respectivement
    # Devrait générer 2 * 3 = 6 combinaisons

    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)
    color_attr.attribute_values.create!(value: "Bleu", position: 2)

    size_attr = @item.item_attributes.create!(name: "Taille", position: 2)
    size_attr.attribute_values.create!(value: "S", position: 1)
    size_attr.attribute_values.create!(value: "M", position: 2)
    size_attr.attribute_values.create!(value: "L", position: 3)

    combinations = @service.generate_combinations
    assert_equal 6, combinations.length
  end

  test "should generate variants correctly" do
    # Créer 2 attributs avec 2 valeurs chacun = 4 combinaisons
    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)
    color_attr.attribute_values.create!(value: "Bleu", position: 2)

    size_attr = @item.item_attributes.create!(name: "Taille", position: 2)
    size_attr.attribute_values.create!(value: "S", position: 1)
    size_attr.attribute_values.create!(value: "M", position: 2)

    # La variante par défaut a été créée automatiquement lors de la création de l'item

    created = @service.generate_variants!

    assert_equal 4, created.length
    assert_equal 5, @item.variants.count  # 4 générées + 1 par défaut créée lors de la création de l'item
  end

  test "should generate variants with correct attributes" do
    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    red_value = color_attr.attribute_values.create!(value: "Rouge", position: 1)
    blue_value = color_attr.attribute_values.create!(value: "Bleu", position: 2)

    size_attr = @item.item_attributes.create!(name: "Taille", position: 2)
    s_value = size_attr.attribute_values.create!(value: "S", position: 1)

    # La variante par défaut a été créée automatiquement lors de la création de l'item

    created = @service.generate_variants!

    assert_equal 2, created.length

    # Vérifier que chaque variante a les bonnes valeurs d'attributs
    created.each do |variant|
      assert_equal 2, variant.attribute_values.count
    end
  end

  test "should not create duplicate variants" do
    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    red_value = color_attr.attribute_values.create!(value: "Rouge", position: 1)

    # Générer une première fois
    created1 = @service.generate_variants!
    assert_equal 1, created1.length
    initial_count = @item.variants.count

    # Générer à nouveau
    created2 = @service.generate_variants!
    assert_empty created2  # Aucune nouvelle variante ne devrait être créée
    assert_equal initial_count, @item.variants.count  # Aucune nouvelle variante
  end

  test "should clear non-default variants" do
    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)

    # Créer une variante non-par-défaut supplémentaire
    non_default_count_before = @item.variants.where(is_default: false).count
    @item.variants.create!(price: 1100, stock_quantity: 40, is_default: false, sku: "#{@item.id}-TEST-1")
    assert_equal non_default_count_before + 1, @item.variants.where(is_default: false).count

    deleted = @service.clear_variants!

    assert_equal 1, deleted
    assert_empty @item.variants.where(is_default: false)
    assert_equal 1, @item.variants.count  # Seulement la variante par défaut
  end

  test "should regenerate variants" do
    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)
    color_attr.attribute_values.create!(value: "Bleu", position: 2)

    # Créer une variante non-par-défaut supplémentaire
    @item.variants.create!(price: 1100, stock_quantity: 40, is_default: false, sku: "#{@item.id}-TEST-2")
    initial_count = @item.variants.count

    @service.regenerate_variants!

    # Après regenerate_variants: l'ancienne variante est supprimée, 2 nouvelles sont créées + 1 par défaut
    assert_equal initial_count + 1, @item.variants.count  # (1 par défaut + 2 générées) vs (1 par défaut + 1 ancienne)
  end

  test "should generate SKU correctly" do
    color_attr = @item.item_attributes.create!(name: "Couleur", position: 1)
    color_attr.attribute_values.create!(value: "Rouge", position: 1)

    created = @service.generate_variants!

    assert_equal 1, created.length
    variant = created.first
    assert variant.sku.present?, "SKU should be present"
    assert_match /ROUGE/, variant.sku, "SKU should contain ROUGE"
  end
end
