# frozen_string_literal: true

class CategoriesController < ApplicationController
  include ItemFiltering
  layout "application"

  allow_unauthenticated_access

  def show
    categories_query = ProductCategoriesQuery.new
    items_query = PublicItemsQuery.new

    @category = categories_query.find_by_slug(params[:slug])
    unless @category
      redirect_to root_path, alert: t("categories.not_found", default: "Catégorie non trouvée")
      return
    end

    # Base query pour les produits de cette catégorie
    sub_category_ids = categories_query.sub_category_ids_for_category(@category)
    @items = items_query.by_sub_category_ids(sub_category_ids)

    # Appliquer les filtres (recherche, prix, boutique, tri)
    @items = apply_item_filters(@items)

    filter_opts = build_filter_options(@items)
    @available_categories = filter_opts[:available_categories]
    @available_sub_categories = filter_opts[:available_sub_categories]
    @available_attribute_values = filter_opts[:available_attribute_values]
    @min_price_available = filter_opts[:min_price_available]
    @max_price_available = filter_opts[:max_price_available]

    # Charger les sous-catégories pour la navigation
    @sub_categories = categories_query.active_sub_categories(@category)

    # Top categories (pour la barre de catégories en haut de page)
    @top_categories = categories_query.top_categories

    # Récupérer les boutiques pour le filtre (avant pagination)
    @shops = items_query.shops_for_items(@items)

    # Items mis en avant (avant pagination) pour l'espace de droite au dessus de la grille
    @featured_items = @items.limit(8)

    # Pagination
    @items = @items.page(params[:page]).per(params[:per_page] || 20)

    # SEO Meta Tags améliorés
    @page_title = "#{@category.name} | #{t('seo.site_name', default: 'aa')}"

    # Meta description améliorée avec nombre de produits (pluralisation correcte)
    items_count = @items.total_count rescue @items.count
    products_label = t("seo.categories.products_count", count: items_count, default: { one: "%{count} produit", other: "%{count} produits" })
    @page_description = @category.description.presence || "Découvrez #{products_label} de la catégorie #{@category.name} sur aa. Livraison rapide au Sénégal. Paiement sécurisé."

    @page_keywords = "#{@category.name.downcase}, produits #{@category.name.downcase}, e-commerce sénégal, #{@category.name.downcase} dakar"

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def sub_category
    categories_query = ProductCategoriesQuery.new
    items_query = PublicItemsQuery.new

    @category = categories_query.find_by_slug(params[:category_slug])
    unless @category
      redirect_to root_path, alert: t("categories.not_found", default: "Catégorie non trouvée")
      return
    end

    @sub_category = @category.sub_categories.friendly.find(params[:sub_category_slug])

    # Base query pour les produits de cette sous-catégorie
    @items = items_query.by_sub_category(@sub_category)

    # Appliquer les filtres (recherche, prix, boutique, tri)
    @items = apply_item_filters(@items)

    filter_opts = build_filter_options(@items)
    @available_categories = filter_opts[:available_categories]
    @available_sub_categories = filter_opts[:available_sub_categories]
    @available_attribute_values = filter_opts[:available_attribute_values]
    @min_price_available = filter_opts[:min_price_available]
    @max_price_available = filter_opts[:max_price_available]

    # Charger les sous-catégories pour la navigation
    @sub_categories = categories_query.active_sub_categories(@category)

    # Top categories (pour la barre de catégories en haut de page)
    @top_categories = categories_query.top_categories

    # Récupérer les boutiques pour le filtre (avant pagination)
    @shops = items_query.shops_for_items(@items)

    # Items mis en avant (avant pagination) pour l'espace de droite au dessus de la grille
    @featured_items = @items.limit(8)

    # Pagination
    @items = @items.page(params[:page]).per(params[:per_page] || 20)

    # SEO Meta Tags améliorés
    @page_title = "#{@sub_category.name} | #{t('seo.site_name', default: 'aa')}"

    # Meta description améliorée avec nombre de produits (pluralisation correcte)
    items_count = @items.total_count rescue @items.count
    products_label = t("seo.categories.products_count", count: items_count, default: { one: "%{count} produit", other: "%{count} produits" })
    @page_description = @sub_category.description.presence || "Découvrez #{products_label} de la sous-catégorie #{@sub_category.name} sur aa. Livraison rapide au Sénégal. Paiement sécurisé."

    @page_keywords = "#{@sub_category.name.downcase}, produits #{@sub_category.name.downcase}, e-commerce sénégal, #{@category.name.downcase} dakar"

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("categories.not_found", default: "Catégorie non trouvée")
  end
end
