# frozen_string_literal: true

class ShopsController < ApplicationController
  include SeoHelper
  include ItemFiltering
  layout :resolve_shop_layout

  allow_unauthenticated_access

  before_action :set_shop, only: :show

  # GET /boutiques (FR) ou /shops (EN)
  # Liste de toutes les boutiques actives
  def index
    # Redirection 301 si accès via /client/shops (ancienne route)
    if request.path.include?("/client/shops")
      query_params = request.query_parameters
      redirect_to shops_path(query_params), status: :moved_permanently
      return
    end

    @shops = Shop.where(status: :active)
                 .includes(:legal_info, logo_attachment: :blob, banner_image_attachment: :blob)
                 .order(created_at: :desc)
                 .page(params[:page])
                 .per(12)

    @available_items_counts = compute_available_items_counts(@shops)

    @page_title = t("seo.shops.index.title", default: "Toutes les boutiques | aa")
    @page_description = t("seo.shops.index.description", default: "Découvrez toutes les boutiques partenaires aa.")
  end

  # GET /boutiques/:slug (FR) ou /shops/:slug (EN)
  # Page de marque / boutique individuelle
  def show
    # Redirection 301 si accès via /client/shops/:slug (ancienne route)
    if request.path.include?("/client/shops/")
      redirect_to shop_path(@shop.slug), status: :moved_permanently
      return
    end

    # Données digitalisées (header slides, sections) pour la page boutique
    page_data = Shops::ShowPageDataService.new(shop: @shop).call
    @shop_page_header_slides = page_data[:shop_page_header_slides]
    @shop_page_sections = page_data[:shop_page_sections]

    # Recalculer les items avec la logique de filtrage unifiée (prix, tri, etc.)
    items_query = PublicItemsQuery.new
    @items = items_query.available_for_sale.where(shop_id: @shop.id)
    @items = apply_item_filters(@items)
    @items = @items.page(params[:page]).per(24)
    @items.load  # Force le SELECT une seule fois, évite les re-queries pour les pluck/select ci-dessous

    # Compteur live (ne dépend pas du cache shops.available_items_count qui peut dériver
    # sur les imports en masse ou update_columns).
    @available_items_count = @shop.items.available_for_sale.count

    current_item_ids = @items.map(&:id)
    sub_category_ids = @items.map(&:product_sub_category_id).compact.uniq

    # Options de filtres disponibles (limitées aux catégories/sous-catégories ayant des produits dans cette boutique)
    @available_sub_categories = ProductSubCategory.where(id: sub_category_ids)
                                                    .includes(:product_category, icon_attachment: :blob)
    category_ids = @available_sub_categories.map(&:product_category_id).uniq
    @available_categories = ProductCategory.where(id: category_ids)

    # Plage de prix disponible (variante par défaut)
    if current_item_ids.any?
      price_range = ItemVariant.where(item_id: current_item_ids, is_default: true).pick(Arel.sql("MIN(price), MAX(price)"))
      @min_price_available, @max_price_available = price_range || [ nil, nil ]
    else
      @min_price_available = @max_price_available = nil
    end

    @featured_products = nil

    # Récupérer les catégories avec leurs produits pour les carrousels (boutiques officielles)
    if @shop.official?
      # Charge UNE seule fois tous les items disponibles + attachments, puis filtre en mémoire
      # pour éviter de re-frapper Postgres et Active Storage à chaque sous-section.
      base_items_loaded = @shop.available_items
        .with_attached_main_image
        .with_attached_images
        .includes(
          :shop,
          :currency,
          :variants,
          :images_attachments,
          images_attachments: :blob,
          main_image_attachment: :blob,
          product_sub_category: { icon_attachment: :blob }
        )
        .to_a

      sub_category_ids_for_official = base_items_loaded.map(&:product_sub_category_id).compact.uniq
      preloaded_sub_categories = ProductSubCategory
                                   .where(id: sub_category_ids_for_official)
                                   .includes(icon_attachment: :blob)
                                   .index_by(&:id)

      @shop_categories_with_products = base_items_loaded
                                            .reject { |item| item.product_sub_category_id.nil? }
                                            .group_by { |item| preloaded_sub_categories[item.product_sub_category_id] }
                                            .compact
                                            .sort_by { |cat, _| cat.position || 0 }
                                            .first(3)
                                            .to_h

      @meilleures_offres = base_items_loaded
                              .select { |item| item.sale_discount_percent.present? && item.on_sale? }
                              .sort_by { |item| -item.sale_discount_percent.to_f }
                              .first(12)
      @nouveautes = []
      @destockage = []
      @featured_products = base_items_loaded.first(5)
    end

    # Fallback (boutiques non officielles) : 5 produits vedettes pour le hero carousel
    @featured_products ||= @shop.available_items
                                  .includes(:variants, main_image_attachment: :blob, images_attachments: :blob)
                                  .limit(5)
                                  .to_a

    # Attributs filtrables (variants) disponibles pour cette boutique (nom d'attribut => liste de valeurs)
    @available_attribute_values = if current_item_ids.any?
      AttributeValue
        .joins(variant_attribute_values: { item_variant: :item })
        .where(items: { id: current_item_ids })
        .joins(:item_attribute)
        .select("attribute_values.id AS id, attribute_values.value AS value, item_attributes.name AS attr_name")
        .distinct
        .group_by(&:attr_name)
        .transform_values { |values| values.map { |v| { id: v.id, value: v.value } } }
    else
      {}
    end

    @page_title = t("seo.shops.show.title", shop_name: @shop.name, default: "#{@shop.name} - Boutique | aa")
    @page_description = @shop.description.presence || t("seo.shops.show.description", shop_name: @shop.name, count: @available_items_count)

    # Track analytics
    @shop.increment_view_count if @shop.respond_to?(:increment_view_count)
    track_event("shop_viewed", {
      Analytics::EventDefinitions::Properties::SHOP_ID => @shop.id,
      Analytics::EventDefinitions::Properties::SHOP_NAME => @shop.name,
      Analytics::EventDefinitions::Properties::SHOP_SLUG => @shop.slug,
      Analytics::EventDefinitions::Properties::VENDOR_ID => @shop.vendor_id
    })

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to shops_path, alert: t("shops.not_found", default: "Boutique non trouvée")
  end

  private

  def resolve_shop_layout
    return "application" unless action_name == "show"

    @shop&.official? ? "shop_official" : "shop_local"
  end

  def set_shop
    @shop = Shop.friendly.find(params[:slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to shops_path, alert: t("shops.not_found", default: "Boutique non trouvée")
  end

  # Vrai nombre de produits disponibles par boutique pour la page courante.
  # Une seule requête groupée — évite la dérive de `shops.available_items_count`.
  def compute_available_items_counts(shops)
    shop_ids = shops.map(&:id)
    return {} if shop_ids.empty?

    Item.available_for_sale.where(shop_id: shop_ids).group(:shop_id).count
  end
end
