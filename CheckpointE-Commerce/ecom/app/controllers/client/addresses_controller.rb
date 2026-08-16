module Client
  class AddressesController < BaseController
    before_action :set_address, only: [ :show, :edit, :update, :destroy, :set_default ]

    def index
      @addresses = current_user.addresses.order(is_default: :desc, created_at: :desc)
      @from_checkout = params[:from_checkout] || session[:from_cart_list]
      session.delete(:from_cart_list) if session[:from_cart_list]
    end

    def show
    end

    def new
      @address = current_user.addresses.new
      # Marquer le retour au checkout si venant du checkout
      session[:return_to_cart] = true if params[:from_checkout]
    end

    def create
      Rails.logger.info("📍 [Client::AddressesController] Création adresse - user_id: #{current_user.id}")
      @address = current_user.addresses.new(address_params)
      @from_checkout = params[:from_checkout].present? || request.referer&.include?("orders/new")

      # Définir automatiquement comme adresse par défaut si c'est la seule adresse de l'utilisateur
      if current_user.addresses.count == 0
        @address.is_default = true
      end

      if @address.save
        Rails.logger.info("✅ [Client::AddressesController] Adresse créée avec succès - address_id: #{@address.id}, user_id: #{current_user.id}")

        respond_to do |format|
          format.turbo_stream do
            # Mettre à jour la page de commande avec la nouvelle adresse (pas de redirection)
            @addresses = current_user.addresses.order(is_default: :desc, created_at: :desc)
            render :create, status: :created
          end
          format.html do
            if @from_checkout || session[:return_to_cart]
              session[:from_cart_list] = true if session[:return_to_cart]
              session.delete(:return_to_cart)
              redirect_to new_client_order_path, notice: "Adresse créée avec succès"
            else
              redirect_to client_addresses_path, notice: "Adresse créée avec succès"
            end
          end
        end
      else
        Rails.logger.warn("⚠️ [Client::AddressesController] Échec création adresse - user_id: #{current_user.id}, erreurs: #{@address.errors.full_messages.join(', ')}")
        respond_to do |format|
          format.turbo_stream do
            # Garder le formulaire visible avec les erreurs (pas de redirection)
            render :create, status: :unprocessable_entity
          end
          format.html do
            render :new, status: :unprocessable_entity
          end
        end
      end
    end

    def edit
    end

    def update
      if @address.update(address_params)
        redirect_to client_addresses_path, notice: "Adresse mise à jour avec succès"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      Rails.logger.info("🗑️ [Client::AddressesController] Suppression adresse - address_id: #{@address.id}, user_id: #{current_user.id}")
      @address.destroy
      redirect_to client_addresses_path, notice: "Adresse supprimée avec succès"
    end

    def set_default
      Rails.logger.info("⭐ [Client::AddressesController] Définir adresse par défaut - address_id: #{@address.id}, user_id: #{current_user.id}")
      current_user.addresses.update_all(is_default: false)
      @address.update(is_default: true)
      redirect_to client_addresses_path, notice: "Adresse définie par défaut"
    end

    private

    def set_address
      @address = current_user.addresses.friendly.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to client_addresses_path, alert: "Adresse non trouvée"
    end

    def address_params
      params.require(:address).permit(
        :street_address,
        :city,
        :postal_code,
        :country,
        :latitude,
        :longitude,
        :is_default
      )
    end
  end
end
