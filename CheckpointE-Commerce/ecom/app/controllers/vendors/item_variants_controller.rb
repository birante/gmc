module Vendors
  class ItemVariantsController < BaseController
    before_action :set_item
    before_action :set_variant, only: [ :edit, :update, :destroy ]

    def index
      @variants = @item.variants.includes(attribute_values: :item_attribute)
      @item_attributes = @item.item_attributes.includes(:attribute_values).ordered

      # Statistiques de ventes
      @total_sales = @item.order_items.joins(:order).where(orders: { status: [ "completed", "delivered" ] }).sum(:quantity)
      @total_revenue = @item.order_items.joins(:order).where(orders: { status: [ "completed", "delivered" ] }).sum(:total_price)

      # Statistiques de visites
      @total_views = @item.views_count || 0
    end

    def new
      @variant = @item.variants.build
      # Récupérer les attributs disponibles pour le produit
      @item_attributes = @item.item_attributes.includes(:attribute_values).ordered
    end

    def create
      @variant = @item.variants.build(variant_params)

      if @variant.save
        redirect_to url_with_shop(vendors_item_variants_path(@item), @current_shop),
                    notice: "Variante créée avec succès"
      else
        @item_attributes = @item.item_attributes.includes(:attribute_values).ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # La vue d'édition sera rendue
    end

    def update
      if @variant.update(variant_params)
        redirect_to safe_return_to_or_default,
                    notice: "Variante mise à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @variant.is_default?
        redirect_to url_with_shop(vendors_item_variants_path(@item), @current_shop),
                    alert: "Impossible de supprimer la variante par défaut"
      elsif @variant.destroy
        redirect_to url_with_shop(vendors_item_variants_path(@item), @current_shop),
                    notice: "Variante supprimée avec succès"
      else
        redirect_to url_with_shop(vendors_item_variants_path(@item), @current_shop),
                    alert: "Erreur lors de la suppression de la variante"
      end
    end

    private

    def set_item
      @item = @current_shop&.items&.friendly&.find(params[:item_id]) if @current_shop
    rescue ActiveRecord::RecordNotFound
      authorize_vendor_item!
    end

    def set_variant
      @variant = @item.variants.find_by(id: params[:id])
      redirect_to url_with_shop(vendors_item_variants_path(@item), @current_shop),
                  alert: "Variante non trouvée" unless @variant
    end

    def variant_params
      params.require(:item_variant).permit(:sku, :price, :stock_quantity, :is_default, :sale_price, attribute_value_ids: [])
    end

    # Only allow internal relative paths to prevent open-redirect.
    def safe_return_to_or_default
      target = params[:return_to].to_s
      if target.start_with?("/") && !target.start_with?("//")
        target
      else
        url_with_shop(vendors_item_variants_path(@item), @current_shop)
      end
    end

    def authorize_vendor_item!
      redirect_to url_with_shop(vendors_items_path, @current_shop),
                  alert: t("common.unauthorized")
    end
  end
end
