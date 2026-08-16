class VariantCreationService
  def initialize(item)
    @item = item
  end

  # Traite les données de variantes venant du formulaire
  # et crée les liens avec les attribute_values correspondants
  def process_variants_with_attributes(variants_data)
    return [] unless variants_data.present?

    created_variants = []

    variants_data.each do |variant_data|
      next if variant_data["_destroy"] == "1"

      # Extraire combination_data
      combination_data = variant_data["combination_data"]

      # Ne garder que les attributs valides pour ItemVariant
      price = variant_data["price"].present? ? variant_data["price"].to_f : 0.01
      price = 0.01 if price <= 0 # Le prix doit être >= 0.01 selon la validation
      stock = variant_data["stock_quantity"].present? ? variant_data["stock_quantity"].to_i : 0

      # Générer un SKU si non fourni
      sku = variant_data["sku"].presence || generate_sku_from_combination(combination_data)

      valid_attributes = {
        sku: sku,
        price: price,
        stock_quantity: stock,
        is_default: false
      }

      # Créer la variante
      variant = @item.variants.build(valid_attributes)

      if variant.save
        # Si combination_data est présent, créer les liens avec les attribute_values
        if combination_data.present?
          link_variant_to_attributes(variant, combination_data)
        end

        created_variants << variant
        Rails.logger.info("✅ [VariantCreationService] Variante créée - SKU: #{variant.sku}")
      else
        Rails.logger.error("❌ [VariantCreationService] Erreur création variante: #{variant.errors.full_messages.join(', ')}")
      end
    end

    created_variants
  end

  private

  # Lie une variante à ses attribute_values
  def link_variant_to_attributes(variant, combination_data)
    return unless combination_data.is_a?(Array)

    combination_data.each do |attr_data_json|
      begin
        # Parser le JSON de l'attribut
        attr_data = JSON.parse(attr_data_json) if attr_data_json.is_a?(String)
        attr_data = attr_data_json if attr_data_json.is_a?(Hash)

        next unless attr_data.present?

        # Trouver l'attribute_value correspondant
        attribute_value = find_or_create_attribute_value(attr_data)

        # Créer le lien si l'attribute_value existe
        if attribute_value
          variant.variant_attribute_values.find_or_create_by(attribute_value: attribute_value)
        end
      rescue JSON::ParserError => e
        Rails.logger.error("❌ [VariantCreationService] Erreur parsing JSON: #{e.message}")
      end
    end
  end

  # Trouve ou crée un attribute_value basé sur les données
  def find_or_create_attribute_value(attr_data)
    attr_name = attr_data["name"]
    attr_value = attr_data["value"]

    return nil unless attr_name.present? && attr_value.present?

    # Trouver l'item_attribute correspondant
    item_attribute = @item.item_attributes.find_by(name: attr_name)

    unless item_attribute
      # Créer l'attribut s'il n'existe pas
      item_attribute = @item.item_attributes.create(
        name: attr_name,
        position: @item.item_attributes.count
      )
    end

    # Trouver ou créer l'attribute_value
    attribute_value = item_attribute.attribute_values.find_by(value: attr_value)

    if attribute_value
      # Compléter les infos couleur si elles arrivent dans combination_data (variantes créées à la volée)
      updates = {}
      updates[:hex_code] = attr_data["hex_code"] if attr_data["hex_code"].present? && attribute_value.hex_code.blank?
      updates[:shop_color_id] = attr_data["shop_color_id"] if attr_data["shop_color_id"].present? && attribute_value.shop_color_id.blank?
      attribute_value.update(updates) if updates.any?
    else
      attribute_value = item_attribute.attribute_values.create(
        value: attr_value,
        position: item_attribute.attribute_values.count,
        hex_code: attr_data["hex_code"].presence,
        shop_color_id: attr_data["shop_color_id"].presence
      )
    end

    attribute_value
  end

  # Génère un SKU basé sur la combinaison d'attributs
  def generate_sku_from_combination(combination_data)
    return "#{@item.id}-#{SecureRandom.hex(4).upcase}" unless combination_data.present?

    parts = []
    combination_data.each do |attr_data_json|
      begin
        attr_data = JSON.parse(attr_data_json) if attr_data_json.is_a?(String)
        attr_data = attr_data_json if attr_data_json.is_a?(Hash)

        if attr_data && attr_data["value"].present?
          parts << attr_data["value"].parameterize.upcase
        end
      rescue JSON::ParserError
        # Ignorer les erreurs de parsing
      end
    end

    "#{@item.id}-#{parts.join('-')}"
  end
end
