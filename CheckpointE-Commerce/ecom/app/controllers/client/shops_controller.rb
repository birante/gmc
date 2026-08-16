# frozen_string_literal: true

module Client
  class ShopsController < ApplicationController
    include SeoHelper

    allow_unauthenticated_access

    before_action :set_shop, only: :show

    # GET /client/shops
    # Liste de toutes les boutiques actives
    # Redirection 301 vers la nouvelle route publique
    def index
      query_params = request.query_parameters
      redirect_to shops_path(query_params), status: :moved_permanently
    end

    # GET /client/shops/:slug
    # Page de marque / boutique individuelle
    # Redirection 301 vers la nouvelle route publique
    def show
      redirect_to shop_path(params[:slug]), status: :moved_permanently
    end

    # GET /client/shops/officielles
    # Boutiques officielles (marques vérifiées)
    def official
      @shops = Shop.where(status: :active)
                   .official_shops
                   .includes(:legal_info, logo_attachment: :blob, banner_image_attachment: :blob)
                   .order(name: :asc)
                   .page(params[:page])
                   .per(12)

      @available_items_counts = compute_available_items_counts(@shops)

      @page_title = t("seo.shops.official.title", default: "Marques officielles | aa")
      @page_description = t("seo.shops.official.description", default: "Achetez auprès des marques officielles partenaires aa.")

      render :index
    end

    # GET /client/shops/locales
    # Boutiques locales sénégalaises
    def local
      @shops = Shop.where(status: :active)
                   .local_shops
                   .includes(:legal_info, logo_attachment: :blob, banner_image_attachment: :blob)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(12)

      @available_items_counts = compute_available_items_counts(@shops)

      @page_title = t("seo.shops.local.title", default: "Boutiques locales sénégalaises | aa")
      @page_description = t("seo.shops.local.description", default: "Découvrez les boutiques sénégalaises partenaires aa.")

      render :index
    end

    private

    def set_shop
      @shop = Shop.friendly.find(params[:slug])
    rescue ActiveRecord::RecordNotFound
      redirect_to client_shops_path, alert: t("shops.not_found", default: "Boutique non trouvée")
    end

    # Calcule le vrai nombre de produits disponibles par boutique pour la page
    # courante en une seule requête, afin de ne pas dépendre du compteur cache
    # `shops.available_items_count` qui peut dériver (imports, update_columns, etc.).
    def compute_available_items_counts(shops)
      shop_ids = shops.map(&:id)
      return {} if shop_ids.empty?

      Item.available_for_sale.where(shop_id: shop_ids).group(:shop_id).count
    end
  end
end
