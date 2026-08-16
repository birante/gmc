module Client
  class ItemsController < BaseController
    skip_before_action :authenticate_client!
    skip_before_action :require_verified_account!, only: [ :index, :show, :recommendations ]
    allow_unauthenticated_access

    def index
      # Redirection 301 vers URLs SEO-friendly si category_id présent
      if params[:category_id].present? && params[:sub_category_id].present?
        category = ProductCategory.find_by(id: params[:category_id])
        sub_category = ProductSubCategory.find_by(id: params[:sub_category_id])
        if category && sub_category && category.id == sub_category.product_category_id
          query_params = request.query_parameters.except(:category_id, :sub_category_id)
          redirect_to category_sub_category_path(category.slug, sub_category.slug, query_params), status: :moved_permanently
          return
        end
      elsif params[:category_id].present?
        category = ProductCategory.find_by(id: params[:category_id])
        if category
          query_params = request.query_parameters.except(:category_id)
          redirect_to category_path(category.slug, query_params), status: :moved_permanently
          return
        end
      end

      # Redirection 301 si accès via /client/items (ancienne route) sans category_id
      if request.path.include?("/client/items") && !request.path.include?("/client/items/recommendations") && !params[:category_id].present?
        query_params = request.query_parameters
        redirect_to items_path(query_params), status: :moved_permanently
        return
      end

      # Logique normale pour la recherche et le listing général
      @items = Item.available_for_sale
                  .includes(:shop, :product_sub_category, :currency, :variants, main_image_attachment: :blob, images_attachments: :blob)
                  .joins("LEFT JOIN item_variants ON item_variants.item_id = items.id AND item_variants.is_default = true")

      # Recherche par nom ou description
      if params[:search].present?
        search_term = "%#{params[:search].strip}%"
        @items = @items.where("items.name ILIKE ? OR items.description ILIKE ?", search_term, search_term)
      end

      # Filtre par catégorie (peut être une ProductCategory ou ProductSubCategory)
      if params[:category_id].present?
        # Vérifier si c'est une sous-catégorie
        sub_category = ProductSubCategory.find_by(id: params[:category_id])
        if sub_category
          @items = @items.where(product_sub_category_id: params[:category_id])
          @sub_category = sub_category
          @category = sub_category.product_category
        else
          # Sinon, c'est une catégorie principale, filtrer par toutes ses sous-catégories
          category = ProductCategory.find_by(id: params[:category_id])
          if category
            sub_category_ids = category.sub_categories.where(is_active: true).pluck(:id)
            @items = @items.where(product_sub_category_id: sub_category_ids) if sub_category_ids.any?
            @category = category
          end
        end
      end

      # Filtre par sous-catégorie
      if params[:sub_category_id].present?
        @items = @items.where(product_sub_category_id: params[:sub_category_id])
        @sub_category = ProductSubCategory.find_by(id: params[:sub_category_id])
        @category = @sub_category&.product_category
      end

      # Charger les sous-catégories pour la navigation
      if @category
        @sub_categories = @category.sub_categories.where(is_active: true).with_attached_icon.order(:position, :name)
      end

      # Top categories (pour la barre de catégories en haut de page)
      @top_categories = ProductCategory.where(is_active: true).with_attached_icon.order(:position, :name).limit(8)

      # Filtre par boutique (marque)
      if params[:shop_ids].present?
        @items = @items.where(shop_id: params[:shop_ids])
      end

      # Filtre par prix
      if params[:min_price].present?
        @items = @items.where("item_variants.price >= ?", params[:min_price].to_f)
      end
      if params[:max_price].present?
        @items = @items.where("item_variants.price <= ?", params[:max_price].to_f)
      end

      # Récupérer les boutiques pour le filtre (avant pagination)
      @shops = Shop.joins(:items)
                   .where(items: { id: @items.select(:id) })
                   .distinct
                   .order(:name)
                   .limit(20)

      # Tri
      case params[:sort]
      when "price_asc"
        @items = @items.order("item_variants.price ASC")
      when "price_desc"
        @items = @items.order("item_variants.price DESC")
      when "newest"
        @items = @items.order("items.created_at DESC")
      when "bestsellers"
        @items = @items.left_joins(:order_items)
                      .group("items.id")
                      .order("COUNT(order_items.id) DESC")
      else
        @items = @items.order("items.created_at DESC")
      end

      # Items mis en avant (avant pagination) pour l'espace de droite au dessus de la grille
      @featured_items = @items.limit(8)

      # Pagination
      @items = @items.page(params[:page]).per(params[:per_page] || 20)
    end

    def show
      # Redirection 301 si accès via /client/items/:id (ancienne route)
      redirect_to item_path(params[:id]), status: :moved_permanently
    end

    def recommendations
      # Base query
      base_query = Item.available_for_sale
                       .select("items.*, item_variants.price")
                       .joins("LEFT JOIN item_variants ON item_variants.item_id = items.id AND item_variants.is_default = true")

      # Filtre par type (tab)
      case params[:tab]
      when "best_deals"
        # Meilleurs deals : produits avec réduction ou prix réduits
        base_query = base_query.where("items.is_on_sale = true").order("items.sale_discount_percent DESC, items.created_at DESC")
      when "best_sales"
        # Meilleures ventes : produits les plus vendus
        base_query = base_query.left_joins(:order_items)
                               .group("items.id, item_variants.price")
                               .order("COUNT(order_items.id) DESC")
      else
        # Recommandations : produits recommandés (par défaut, les plus récents)
        base_query = base_query.order("items.created_at DESC")
      end

      # Filtre par catégorie
      if params[:category_id].present?
        category = ProductCategory.find_by(id: params[:category_id])
        if category
          sub_category_ids = category.sub_categories.where(is_active: true).pluck(:id)
          base_query = base_query.where(product_sub_category_id: sub_category_ids) if sub_category_ids.any?
        end
      end

      # Tri
      case params[:sort]
      when "price_asc"
        base_query = base_query.order("item_variants.price ASC")
      when "price_desc"
        base_query = base_query.order("item_variants.price DESC")
      when "newest"
        base_query = base_query.order("items.created_at DESC")
      else
        # Relevant ou défaut
        base_query = base_query.order("items.created_at DESC")
      end

      # Pagination : 12 produits par page
      # Important : pas de .distinct ici car cela cause une erreur PostgreSQL
      # "ORDER BY expressions must appear in select list" avec SELECT DISTINCT
      @items = base_query
               .includes(:shop, :product_sub_category, :currency, main_image_attachment: :blob, images_attachments: :blob, variants: [])
               .page(params[:page])
               .per(12)

      respond_to do |format|
        format.html { render partial: "shared/storefront/recommendation_items", locals: { items: @items }, layout: false }
        format.json { render json: { items: @items, total_count: @items.total_count, has_more: @items.current_page < @items.total_pages } }
      end
    end
  end
end
