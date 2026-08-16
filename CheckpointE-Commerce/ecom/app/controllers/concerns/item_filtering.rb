# frozen_string_literal: true

# Concern pour centraliser la logique de filtrage des produits
# Utilisé par ItemsController, CategoriesController, etc.
module ItemFiltering
  extend ActiveSupport::Concern

  private

  # Applique tous les filtres sur une collection d'items
  def apply_item_filters(items_scope)
    # Recherche : combine pg_search (tolérance aux fautes, prefix) et un
    # fallback ILIKE sur nom / slug / description + nom de la boutique et de
    # la sous-catégorie. Ça garantit que les correspondances "substring"
    # évidentes ("produit", "sac"…) ne soient jamais manquées par pg_search.
    # Si pg_trgm est indisponible (dev local sans extension), on retombe
    # silencieusement sur ILIKE seul.
    if params[:search].present?
      term = params[:search].strip
      like = "%#{term}%"
      fuzzy_ids = begin
        Item.search_fuzzy(term).limit(500).pluck(:id)
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.warn("[ItemFiltering] search_fuzzy indisponible : #{e.message.lines.first&.strip}")
        []
      end
      ilike_ids = Item
                    .left_joins(:shop, :product_sub_category)
                    .where(
                      "items.name ILIKE :t OR items.slug ILIKE :t OR items.description ILIKE :t OR shops.name ILIKE :t OR product_sub_categories.name ILIKE :t",
                      t: like
                    )
                    .distinct
                    .limit(500)
                    .pluck(:id)
      items_scope = items_scope.where(id: (fuzzy_ids + ilike_ids).uniq)
    end

    # Filtre par boutique (marque)
    if params[:shop_ids].present?
      shop_ids = Array(params[:shop_ids]).reject(&:blank?)
      items_scope = items_scope.where(shop_id: shop_ids) if shop_ids.any?
    end

    # Filtre par prix minimum
    if params[:min_price].present?
      items_scope = items_scope.where("item_variants.price >= ?", params[:min_price].to_f)
    end

    # Filtre par prix maximum
    if params[:max_price].present?
      items_scope = items_scope.where("item_variants.price <= ?", params[:max_price].to_f)
    end

    # Filtre par catégorie (ProductCategory) - multi sélection
    if params[:product_category_ids].present?
      category_ids = Array(params[:product_category_ids]).reject(&:blank?)
      if category_ids.any?
        subcat_ids = ProductSubCategory.where(product_category_id: category_ids).pluck(:id)
        items_scope = items_scope.where(product_sub_category_id: subcat_ids) if subcat_ids.any?
      end
    end

    # Filtre par sous-catégorie (ProductSubCategory) - multi sélection
    if params[:product_sub_category_ids].present?
      subcat_ids = Array(params[:product_sub_category_ids]).reject(&:blank?)
      items_scope = items_scope.where(product_sub_category_id: subcat_ids) if subcat_ids.any?
    end

    # Filtre par attributs de variantes (AttributeValue) - exige que la même variante possède toutes les valeurs sélectionnées
    if params[:attribute_value_ids].present?
      value_ids = Array(params[:attribute_value_ids]).reject(&:blank?)
      if value_ids.any?
        items_scope = items_scope
          .joins(variants: :variant_attribute_values)
          .where(variant_attribute_values: { attribute_value_id: value_ids })
          .group("items.id")
          .having("COUNT(DISTINCT variant_attribute_values.attribute_value_id) >= ?", value_ids.size)
      end
    end

    # Appliquer le tri
    items_scope = apply_sorting(items_scope)

    items_scope
  end

  # Construit les options de filtres disponibles pour un scope d'items
  def build_filter_options(items_scope)
    # On retire le ORDER BY pour éviter les erreurs PostgreSQL sur les requêtes DISTINCT
    scope_for_filters = items_scope.reorder(nil)

    # Sous-catégories présentes dans le scope
    sub_category_ids = scope_for_filters.where.not(product_sub_category_id: nil).distinct.pluck(:product_sub_category_id)
    available_sub_categories = ProductSubCategory.where(id: sub_category_ids)

    # Catégories correspondantes
    category_ids = available_sub_categories.map(&:product_category_id).uniq
    available_categories = ProductCategory.where(id: category_ids)

    # Plage de prix (variants par défaut)
    default_variant_prices = ItemVariant.where(item_id: scope_for_filters.select(:id), is_default: true)
    min_price_available = default_variant_prices.minimum(:price)
    max_price_available = default_variant_prices.maximum(:price)

    # Attributs de variantes disponibles
    attribute_rows = AttributeValue
                       .joins(variant_attribute_values: { item_variant: :item })
                       .where(items: { id: scope_for_filters.select(:id) })
                       .joins(:item_attribute)
                       .select("attribute_values.id AS id, attribute_values.value AS value, item_attributes.name AS attr_name")
                       .distinct

    available_attribute_values = attribute_rows.group_by(&:attr_name).transform_values do |values|
      values.map { |v| { id: v.id, value: v.value } }
    end

    {
      available_categories: available_categories,
      available_sub_categories: available_sub_categories,
      min_price_available: min_price_available,
      max_price_available: max_price_available,
      available_attribute_values: available_attribute_values
    }
  end

  # Applique le tri sur une collection d'items
  def apply_sorting(items_scope)
    case params[:sort]
    when "price_asc"
      items_scope.order("item_variants.price ASC")
    when "price_desc"
      items_scope.order("item_variants.price DESC")
    when "newest"
      items_scope.order("items.created_at DESC")
    when "bestsellers"
      items_scope.left_joins(:order_items)
                 .group("items.id")
                 .order("COUNT(order_items.id) DESC")
    else
      # Par défaut, trier par date de création (plus récents en premier)
      items_scope.order("items.created_at DESC")
    end
  end
end
