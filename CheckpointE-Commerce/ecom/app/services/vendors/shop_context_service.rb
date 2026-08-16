module Vendors
  class ShopContextService
    Result = Struct.new(:success, :shop, :shops, :error)

    def initialize(vendor, params:, session:, available_shops: nil)
      @vendor = vendor
      @params = params
      @session = session
      # Utiliser available_shops si fourni (pour les employés), sinon toutes les boutiques du vendor
      @shops = available_shops || vendor.shops.order(created_at: :desc)
    end

    def current_shop
      @current_shop ||= determine_current_shop
    end

    def update_session
      return unless current_shop && current_shop.persisted?

      @session[:current_shop_slug] = current_shop.slug
      @session[:current_shop_id] = current_shop.id # Keep for backward compatibility
    end

    def shop_filter_condition
      @shop_filter_condition ||= build_shop_filter
    end

    def shop_condition_sql
      shop_filter_condition[:sql]
    end

    def shop_condition_value
      shop_filter_condition[:value]
    end

    def shops
      @shops
    end

    private

    def determine_current_shop
      # 1. Depuis les params (shop_slug ou shop_id pour compatibilité)
      shop = find_shop_from_params
      return shop if shop

      # 2. Si on est sur edit shop, utiliser le slug/id de la boutique
      shop = find_shop_from_edit_action
      return shop if shop

      # 3. Depuis la session
      shop = find_shop_from_session
      return shop if shop

      # 4. Par défaut : première boutique
      @shops.first
    end

    def find_shop_from_params
      return nil unless @params[:shop_slug].present? || @params[:shop_id].present?

      begin
        if @params[:shop_slug].present?
          shop = @shops.friendly.find_by(slug: @params[:shop_slug])
          # Vérifier que la boutique appartient bien au vendor et est dans les boutiques disponibles
          shop if shop && shop.vendor_id == @vendor.id
        elsif @params[:shop_id].present?
          # Backward compatibility: try to find by slug first, then by id
          shop = @shops.friendly.find(@params[:shop_id]) rescue @shops.find_by(id: @params[:shop_id])
          # Vérifier que la boutique appartient bien au vendor et est dans les boutiques disponibles
          shop if shop && shop.vendor_id == @vendor.id
        end
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end

    def find_shop_from_edit_action
      return nil unless @params[:controller] == "vendors/shops" && @params[:action] == "edit" && @params[:id].present?

      begin
        shop = @shops.friendly.find(@params[:id])
        # Vérifier que la boutique appartient bien au vendor et est dans les boutiques disponibles
        shop if shop && shop.vendor_id == @vendor.id
      rescue ActiveRecord::RecordNotFound
        # If not found with friendly, try with id
        if @params[:id].match?(/^\d+$/)
          shop = @shops.find_by(id: @params[:id])
          shop if shop && shop.vendor_id == @vendor.id
        end
      end
    end

    def find_shop_from_session
      return nil unless @session[:current_shop_slug].present? || @session[:current_shop_id].present?

      begin
        shop = if @session[:current_shop_slug].present?
                 @shops.friendly.find_by(slug: @session[:current_shop_slug])
        elsif @session[:current_shop_id].present?
                 @shops.find_by(id: @session[:current_shop_id])
        end

        # Vérifier que la boutique existe toujours, appartient au vendor et est dans les boutiques disponibles
        # Si elle n'existe plus ou n'appartient plus au vendor, nettoyer la session
        if shop.nil? || shop.vendor_id != @vendor.id
          @session.delete(:current_shop_slug)
          @session.delete(:current_shop_id)
          return nil
        end

        shop
      rescue ActiveRecord::RecordNotFound
        # Nettoyer la session si la boutique n'existe plus
        @session.delete(:current_shop_slug)
        @session.delete(:current_shop_id)
        nil
      end
    end

    def build_shop_filter
      if current_shop && current_shop.persisted?
        {
          sql: "shops.id = ?",
          value: current_shop.id
        }
      else
        {
          sql: "shops.vendor_id = ?",
          value: @vendor.id
        }
      end
    end
  end
end
