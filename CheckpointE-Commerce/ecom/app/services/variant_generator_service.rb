class VariantGeneratorService
  def initialize(item)
    @item = item
  end

  # Génère toutes les combinaisons de variantes basées sur les attributs
  # Exemple: si on a 2 couleurs x 3 tailles = 6 variantes générées
  def generate_combinations
    return [] if @item.item_attributes.empty?

    # Récupérer toutes les valeurs d'attributs ordonnées
    attributes_with_values = @item.item_attributes.ordered.map do |attr|
      {
        attribute: attr,
        values: attr.attribute_values.ordered
      }
    end

    # Générer le produit cartésien (toutes les combinaisons)
    combinations = generate_cartesian_product(attributes_with_values)

    Rails.logger.info("🎯 [VariantGenerator] Génération de #{combinations.length} combinaisons pour item_id: #{@item.id}")

    combinations
  end

  # Crée toutes les variantes basées sur les combinaisons d'attributs
  # Les variantes existantes ne sont pas supprimées, seulement les nouvelles sont créées
  def generate_variants!(default_price = nil, default_stock = nil)
    combinations = generate_combinations
    created_variants = []
    skipped_count = 0

    default_variant = @item.default_variant

    combinations.each_with_index do |combination, index|
      # Vérifier si la combinaison existe déjà
      if variant_exists?(combination)
        skipped_count += 1
        next
      end

      variant = @item.variants.build(
        is_default: false,
        price: default_price || default_variant&.price || 0,
        stock_quantity: default_stock || default_variant&.stock_quantity || 0
      )

      # Save the variant first without SKU validation
      variant.sku = "TEMP-#{SecureRandom.uuid}"

      if variant.save
        # Assigner les valeurs d'attributs après la sauvegarde
        combination.each do |attribute_value|
          variant.attribute_values << attribute_value
        end

        # Générer le SKU maintenant que les attribute_values sont sauvegardées
        variant.sku = generate_variant_sku(variant)
        variant.save!

        created_variants << variant
        Rails.logger.info("✅ [VariantGenerator] Variante créée - SKU: #{variant.sku}, combinaison: #{combination.map(&:value).join(' / ')}")
      else
        Rails.logger.error("❌ [VariantGenerator] Erreur création variante - Erreurs: #{variant.errors.full_messages.join(', ')}")
      end
    end

    Rails.logger.info("✨ [VariantGenerator] Génération terminée - créées: #{created_variants.length}, ignorées: #{skipped_count}, total: #{combinations.length}")

    created_variants
  end

  # Supprime toutes les variantes qui ne sont pas par défaut
  def clear_variants!
    deleted_count = @item.variants.where(is_default: false).delete_all
    Rails.logger.info("🗑️ [VariantGenerator] #{deleted_count} variantes supprimées pour item_id: #{@item.id}")
    deleted_count
  end

  # Régénère les variantes (supprime les anciennes et en crée des nouvelles)
  def regenerate_variants!(default_price = nil, default_stock = nil)
    clear_variants!
    generate_variants!(default_price, default_stock)
  end

  private

  # Génère le produit cartésien (toutes les combinaisons possibles)
  # Exemple: [[Couleur1, Couleur2], [Taille1, Taille2, Taille3]] =>
  #          [[Couleur1, Taille1], [Couleur1, Taille2], ..., [Couleur2, Taille3]]
  def generate_cartesian_product(attributes_with_values)
    value_lists = attributes_with_values.map { |attr| attr[:values] }

    # Cas spécial : s'il n'y a qu'un seul attribut
    return value_lists[0].map { |v| [ v ] } if value_lists.length == 1

    # Générer le produit cartésien de manière récursive
    # On commence avec le premier liste wrappée dans un array
    first_list = value_lists[0].map { |v| [ v ] }

    value_lists[1..-1].inject(first_list) do |combinations, values|
      combinations.flat_map do |combination|
        values.map { |value| combination + [ value ] }
      end
    end
  end

  # Vérifie si une combinaison d'attributs existe déjà pour cet item
  def variant_exists?(attribute_values)
    attribute_value_ids = attribute_values.map(&:id).sort

    @item.variants.each do |variant|
      variant_attr_ids = variant.attribute_values.pluck(:id).sort
      return true if variant_attr_ids == attribute_value_ids
    end

    false
  end

  # Génère le SKU pour une variante basé sur ses attribute_values
  def generate_variant_sku(variant)
    parts = [ @item.id ]
    @item.item_attributes.ordered.each do |attr|
      value = variant.attribute_values.joins(:item_attribute)
        .where(item_attributes: { id: attr.id })
        .first&.value
      parts << value.upcase if value.present?
    end
    parts.join("-")
  end
end
