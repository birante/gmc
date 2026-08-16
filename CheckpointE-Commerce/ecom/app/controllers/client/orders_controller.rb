module Client
  class OrdersController < BaseController
    before_action :set_order, only: [ :show ]

    def index
      query = ClientOrdersQuery.new(user: current_user)
      filters = { status: params[:status] }
      @orders = query.call(filters: filters)

      # Pagination avec Kaminari
      @orders = @orders.page(params[:page]).per(10)

      # Préchargement des avis du user pour les items des commandes affichées (évite N+1)
      item_ids = @orders.flat_map { |o| o.order_items.map(&:item_id) }.uniq
      @reviews_by_item_id = current_user.reviews.where(item_id: item_ids).index_by(&:item_id)
    end

    def show
      # Forcer le recalcul du statut de la commande au moment de l'affichage
      # pour s'assurer qu'il est à jour avec les statuts des items
      @order.calculate_status_from_items!
      @order.reload
    end

    def new
      # Vérifier si l'utilisateur est connecté
      unless current_user
        session[:return_to] = new_client_order_path
        redirect_to new_client_registration_path, alert: "Veuillez créer un compte pour valider votre commande"
        return
      end

      prepare_checkout_context
      nil if performed?
    end

    # Action AJAX pour charger les créneaux d'une zone
    def get_delivery_slots
      @delivery_zone = DeliveryZone.active.find_by(id: params[:delivery_zone_id])
      @delivery_slots = @delivery_zone&.delivery_slots&.active || []

      # Calculer les frais de livraison basés sur la catégorie la plus grande du panier
      delivery_fee = if @delivery_zone
        calculate_delivery_fee_for_cart(@delivery_zone)
      else
        0.0
      end

      render json: {
        slots: @delivery_slots.map { |slot| { id: slot.id, time_range: slot.time_range } },
        base_fee: delivery_fee.to_f
      }
    end

    def create
      Rails.logger.info("[Client::OrdersController] Début création commande - user_id: #{current_user.id}, cart_id: #{current_cart&.id}")
      prepare_checkout_context
      return if performed?

      service = Checkout::FinalizeOrderService.new(
        user: current_user,
        cart: current_cart,
        params: checkout_params
      )

      result = service.call

      if result.success?
        Rails.logger.info("[Client::OrdersController] Commande créée avec succès - order_id: #{result.order.id}, montant: #{result.order.final_amount}")
        @current_cart = nil

        # Vérifier si c'est un paiement PayDunya PAR qui nécessite une redirection
        if result.paydunya_redirect_url.present?
          Rails.logger.info("[Client::OrdersController] Redirection vers PayDunya - url: #{result.paydunya_redirect_url}")
          # Afficher une page de transition avant la redirection
          @redirect_url = result.paydunya_redirect_url
          render template: "paydunya_callbacks/redirecting", layout: false
        else
          redirect_to client_orders_path, notice: "✅ Paiement confirmé! Votre commande est en cours de traitement."
        end
      else
        Rails.logger.warn("[Client::OrdersController] Échec création commande - user_id: #{current_user.id}, erreurs: #{result.errors.join(', ')}")
        @order = result.order || current_user.orders.new
        flash.now[:alert] = result.errors.compact.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    private

    def prepare_checkout_context
      @order = current_user.orders.new
      @cart = current_cart

      if @cart.blank? || @cart.cart_items.empty?
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
        redirect_to redirect_url, alert: "Votre panier est vide"
        return
      end

      @addresses = current_user.addresses.order(is_default: :desc, created_at: :desc)
      params_hash = checkout_params.to_h rescue {}
      @selected_address_slug = params_hash[:address_id]&.presence || current_user.default_address&.slug
      @delivery_zones = DeliveryZone.active
      delivery_zone_id = params[:delivery_zone_id] rescue nil
      delivery_zone_id ||= params_hash[:delivery_zone_id]
      @selected_zone = @delivery_zones.find_by(id: delivery_zone_id)
      @delivery_slots = @selected_zone ? @selected_zone.delivery_slots.active : []
      @selected_slot_id = params_hash[:delivery_slot_id]&.presence
      @new_address = current_user.addresses.new

      # Frais de livraison : uniquement si une zone est explicitement sélectionnée.
      # Sinon nil → la vue affiche un placeholder, et le total reste égal au sous-total.
      @initial_delivery_fee = @selected_zone ? calculate_delivery_fee_for_cart(@selected_zone) : nil

      @cart_cash_delivery_blocked = @cart.cash_on_delivery_blocked?
      @cart_effective_payment_codes = @cart.effective_allowed_payment_codes
    end

    def checkout_params
      return {} unless params.respond_to?(:permit)
      params.permit(
        :address_id,
        :delivery_zone_id,
        :delivery_slot_id,
        :notes,
        :payment_method
      ) || {}
    end

    def set_order
      @order = current_user.orders
                         .includes(order_items: { item: [ :product_sub_category, main_image_attachment: :blob ], item_variant: { attribute_values: :item_attribute }, shop: {} }, delivery_zone: {}, delivery_slot: {}, currency: {}, user: {}, payments: :payment_method, order_status_histories: :changed_by)
                         .friendly.find(params[:id])
      @status_history = @order.order_status_histories.ordered
    rescue ActiveRecord::RecordNotFound
      redirect_to client_orders_path, alert: "Commande non trouvée"
    end

    # Calcule les frais de livraison basés sur la catégorie la plus grande du panier
    def calculate_delivery_fee_for_cart(delivery_zone)
      return 0.0 unless delivery_zone.present?
      return delivery_zone.base_fee || 0.0 unless current_cart.present?

      # Récupérer toutes les catégories de livraison des produits du panier
      categories = current_cart.cart_items.includes(item: :delivery_category)
                                 .map { |ci| ci.item&.delivery_category }
                                 .compact

      return delivery_zone.base_fee || 0.0 if categories.empty?

      # Trouver la catégorie la plus grande (celle avec le display_order le plus élevé)
      largest_category = DeliveryCategory.largest_among(categories)
      return delivery_zone.base_fee || 0.0 unless largest_category.present?

      # Utiliser le prix spécifique pour cette catégorie et cette zone
      delivery_price = DeliveryPrice.find_price(delivery_zone.id, largest_category.id)

      # Si aucun prix spécifique n'est trouvé, utiliser le base_fee de la zone
      delivery_price > 0 ? delivery_price : (delivery_zone.base_fee || 0.0)
    end
  end
end
