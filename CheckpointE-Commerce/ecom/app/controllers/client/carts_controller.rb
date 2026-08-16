module Client
  class CartsController < BaseController
    skip_before_action :authenticate_client!
    allow_unauthenticated_access

    def show
      @cart = current_cart

      render(:widget, layout: false) if params[:frame].present?
    end

    def clear
      Rails.logger.info("🗑️ [Client::CartsController] Vidage du panier - cart_id: #{current_cart.id}, nombre_items: #{current_cart.cart_items.count}, user_id: #{current_user&.id}")
      current_cart.cart_items.destroy_all
      current_cart.reload
      respond_to do |format|
        redirect_url = if request.referer.present?
          begin
            redirect_uri = URI.parse(request.referer)
            if redirect_uri.query.present?
              params = URI.decode_www_form(redirect_uri.query).to_h
              params["cart"] = "open"
              redirect_uri.query = URI.encode_www_form(params)
            else
              redirect_uri.query = "cart=open"
            end
            redirect_uri.to_s
          rescue URI::InvalidURIError
            root_path(cart: "open")
          end
        else
          root_path(cart: "open")
        end
        format.html { redirect_to redirect_url, notice: "Panier vidé avec succès" }
        format.turbo_stream { render :clear }
      end
    end
  end
end
