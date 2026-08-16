# frozen_string_literal: true

class ItemsController < ApplicationController
  include ItemFiltering
  layout "application"

  allow_unauthenticated_access

  def index
    categories_query = ProductCategoriesQuery.new
    items_query = PublicItemsQuery.new

    # Redirection 301 vers URLs SEO-friendly si category_id présent
    if params[:category_id].present? && params[:sub_category_id].present?
      category = categories_query.find_by_id(params[:category_id])
      sub_category = categories_query.find_sub_category_by_id(params[:sub_category_id])
      if category && sub_category && category.id == sub_category.product_category_id
        query_params = request.query_parameters.except(:category_id, :sub_category_id)
        redirect_to category_sub_category_path(category.slug, sub_category.slug, query_params), status: :moved_permanently
        return
      end
    elsif params[:category_id].present?
      category = categories_query.find_by_id(params[:category_id])
      if category
        query_params = request.query_parameters.except(:category_id)
        redirect_to category_path(category.slug, query_params), status: :moved_permanently
        return
      end
    end

    # Redirection 301 si accès via /client/items (ancienne route)
    if request.path.include?("/client/items") && !request.path.include?("/client/items/recommendations")
      query_params = request.query_parameters
      redirect_to items_path(query_params), status: :moved_permanently
      return
    end

    # Logique normale pour la recherche et le listing général
    @items = items_query.available_for_sale

    # Appliquer les filtres (recherche, prix, boutique, tri)
    @items = apply_item_filters(@items)

    filter_opts = build_filter_options(@items)
    @available_categories = filter_opts[:available_categories]
    @available_sub_categories = filter_opts[:available_sub_categories]
    @available_attribute_values = filter_opts[:available_attribute_values]
    @min_price_available = filter_opts[:min_price_available]
    @max_price_available = filter_opts[:max_price_available]

    # Catégories à afficher dans la rangée du haut. On utilise les sub-categories
    # populaires (qui ont des icônes uploadées) plutôt que les ProductCategory top-level
    # (qui n'en ont pas → afficheraient le placeholder SVG sur 8 colonnes).
    @top_categories = categories_query.featured_sub_categories

    # Récupérer les boutiques pour le filtre (avant pagination)
    @shops = items_query.shops_for_items(@items)

    # Boutiques correspondantes : union entre les boutiques matchant la
    # recherche par nom/description et celles ayant au moins un produit
    # dans les résultats filtrés. Sans cette union, une recherche large
    # ("produit", "sac"…) affichait seulement les boutiques dont le nom
    # contenait le mot-clé, ignorant celles matchant via leurs produits.
    @matching_shops = if params[:search].present?
      term = "%#{params[:search].strip}%"
      by_name_ids = Shop.where(status: :active)
                        .where("shops.name ILIKE :t OR shops.description ILIKE :t", t: term)
                        .pluck(:id)
      by_items_ids = @shops.reorder(nil).pluck(:id)
      Shop.where(status: :active, id: (by_name_ids + by_items_ids).uniq).order(:name).limit(12)
    else
      Shop.none
    end

    # « Nouveautés & En promotion » : mix d'items réellement en promotion
    # active (Item#on_sale) + d'items récents. On respecte les filtres en
    # cours (@items) mais on ne rend PAS n'importe quels 8 items.
    on_sale_items = @items.reorder(nil).on_sale.order(created_at: :desc).limit(8).to_a
    new_items = @items.reorder(nil)
                      .where("items.created_at >= ?", 30.days.ago)
                      .where.not(id: on_sale_items.map(&:id))
                      .order(created_at: :desc)
                      .limit(8 - on_sale_items.size)
                      .to_a
    @featured_items = (on_sale_items + new_items).first(8)

    # Pagination
    @items = @items.includes(item_attributes: :attribute_values)
                   .page(params[:page]).per(params[:per_page] || 20)

    # SEO Meta Tags
    @page_title = t("seo.items.index.title", default: "Tous les produits | aa")
    @page_description = t("seo.items.index.description", default: "Découvrez tous nos produits sur aa. Livraison rapide au Sénégal.")

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    # Redirection 301 si accès via /client/items/:id (ancienne route)
    if request.path.include?("/client/items/")
      redirect_to item_path(params[:id]), status: :moved_permanently
      return
    end

    items_query = PublicItemsQuery.new
    @item = items_query.find_by_slug(params[:id])

    unless @item
      redirect_to items_path, alert: t("items.not_found", default: "Article non trouvé")
      return
    end

    # Charger les autres produits de la boutique (pour le carousel)
    @shop_items = items_query.shop_items_for_item(@item, exclude_item_id: @item.id)

    # Sélection initiale via ?variant_id= ; sinon variante par défaut
    requested_variant = params[:variant_id].present? ? @item.variants.find_by(id: params[:variant_id]) : nil
    @selected_variant = requested_variant || @item.default_variant || @item.variants.first

    # Payload exposé au front pour le sélecteur cross-attribut (Stimulus)
    @variant_payload = build_variant_payload(@item)

    # SEO Meta Tags
    @page_title = "#{@item.name} | #{t('seo.site_name', default: 'aa')}"

    # Meta description améliorée avec plus de détails
    variant = @item.default_variant || @item.variants.first
    price_info = if variant && @item.currency
      "#{ActionController::Base.helpers.number_to_currency(variant.price, unit: @item.currency.symbol, precision: 0)}"
    else
      ""
    end
    category_info = @item.product_sub_category ? " dans la catégorie #{@item.product_sub_category.name}" : ""
    @page_description = @item.description.presence || "Découvrez #{@item.name}#{category_info} sur aa. #{price_info}. Livraison rapide au Sénégal. Paiement sécurisé."

    @page_keywords = "#{@item.name.downcase}, #{@item.product_sub_category&.name&.downcase}, e-commerce sénégal, #{@item.shop&.name&.downcase}"

    track_event("item_viewed", {
      Analytics::EventDefinitions::Properties::ITEM_ID => @item.id,
      Analytics::EventDefinitions::Properties::ITEM_NAME => @item.name,
      Analytics::EventDefinitions::Properties::ITEM_PRICE => variant&.price,
      Analytics::EventDefinitions::Properties::SHOP_ID => @item.shop_id,
      Analytics::EventDefinitions::Properties::SHOP_NAME => @item.shop&.name,
      Analytics::EventDefinitions::Properties::ITEM_CATEGORY => @item.product_category&.name,
      Analytics::EventDefinitions::Properties::ITEM_SUB_CATEGORY => @item.product_sub_category&.name
    })
  end

  private

  # Construit la structure JSON consommée par variant_selector_controller.js
  # - attributes : liste ordonnée des attributs (Couleur, Taille…) avec leurs valeurs distinctes
  # - variants   : tableau plat de variantes avec leur empreinte d'attributs (attrs)
  def build_variant_payload(item)
    variants = item.variants.to_a
    h = helpers

    attributes = item.item_attributes.ordered.map do |attr|
      values = variants
        .flat_map { |v| v.attribute_values.select { |av| av.item_attribute_id == attr.id } }
        .uniq(&:id)
        .sort_by { |av| [ av.position || 0, av.value.to_s ] }
        .map { |av| { id: av.id, value: av.value, hex_code: av.hex_code } }

      { id: attr.id, name: attr.name, values: values }
    end

    variants_payload = variants.map do |v|
      attrs_hash = v.attribute_values.each_with_object({}) do |av, hash|
        hash[av.item_attribute.name] = av.value
      end

      current = h.current_price_for(v)
      original = h.original_price_for(v)

      {
        id: v.id,
        sku: v.sku,
        price: current.to_i,
        price_formatted: h.number_to_currency(current, unit: "", precision: 0, delimiter: ".", separator: ","),
        original_price: original.to_i,
        original_price_formatted: h.number_to_currency(original, unit: "", precision: 0, delimiter: ".", separator: ","),
        discount: h.discount_percentage_for(v),
        stock: v.stock_quantity,
        in_stock: v.in_stock?,
        attrs: attrs_hash
      }
    end

    { attributes: attributes, variants: variants_payload, currency_symbol: item.currency&.symbol }
  end
end
