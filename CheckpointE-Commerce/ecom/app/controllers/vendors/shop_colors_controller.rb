module Vendors
  class ShopColorsController < BaseController
    before_action :require_current_shop!
    before_action :set_shop_color, only: [ :edit, :update, :archive, :restore ]

    def index
      @active_colors = @current_shop.shop_colors.active.ordered
      @archived_colors = @current_shop.shop_colors.archived.ordered
    end

    def new
      @shop_color = @current_shop.shop_colors.new(hex_code: "#551694")
    end

    def create
      @shop_color = @current_shop.shop_colors.new(shop_color_params)

      if @shop_color.save
        redirect_to url_with_shop(vendors_colors_path, @current_shop), notice: "Couleur ajoutée à la palette."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shop_color.update(shop_color_params)
        redirect_to url_with_shop(vendors_colors_path, @current_shop), notice: "Couleur mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def archive
      @shop_color.archive!
      redirect_to url_with_shop(vendors_colors_path, @current_shop),
                  notice: "Couleur archivée. Les produits déjà associés restent inchangés."
    end

    def restore
      @shop_color.unarchive!
      redirect_to url_with_shop(vendors_colors_path, @current_shop), notice: "Couleur restaurée dans la palette."
    end

    private

    def require_current_shop!
      return if @current_shop
      redirect_to vendors_dashboard_path, alert: "Sélectionnez une boutique pour gérer sa palette."
    end

    def set_shop_color
      @shop_color = @current_shop.shop_colors.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to url_with_shop(vendors_colors_path, @current_shop), alert: "Couleur introuvable."
    end

    def shop_color_params
      params.require(:shop_color).permit(:name, :hex_code, :position)
    end
  end
end
