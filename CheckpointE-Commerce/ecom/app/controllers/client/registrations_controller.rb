module Client
  class RegistrationsController < ApplicationController
    allow_unauthenticated_access

    layout "client_onboarding", only: [ :new, :create ]

    before_action :redirect_if_authenticated, only: [ :new, :create ]

    def new
      @user = User.new
      # Sauvegarder l'URL de retour si fournie en paramètre (validation contre Open Redirect)
      if params[:return_to].present? && safe_redirect_url?(params[:return_to])
        session[:return_to_after_verification] = params[:return_to]
      end
    end

    def create
      Rails.logger.info("🎫 [Client::RegistrationsController] Tentative d'inscription client - email: #{registration_params[:email_address]}, téléphone: #{registration_params[:phone_number]}")
      result = Clients::RegistrationService.create(registration_params)
      if result.success
        Rails.logger.info("✅ [Client::RegistrationsController] Enregistrement pending créé - pending_id: #{result.pending_registration.id}")
        # Terminer toute session vendor existante
        session.delete(:vendor_id)

        # Stocker l'ID du pending registration pour la vérification
        session[:pending_registration_id] = result.pending_registration.id
        session[:pending_registration_type] = "User"

        redirect_to new_client_verification_path,
                    notice: t("client.registrations.create.success")
      else
        # Gérer les erreurs (peut être ActiveModel::Errors ou Array)
        error_messages = if result.errors.respond_to?(:full_messages)
          result.errors.full_messages.join(", ")
        else
          Array(result.errors).join(", ")
        end
        Rails.logger.warn("⚠️ [Client::RegistrationsController] Échec inscription client - erreurs: #{error_messages}")
        @user = result.user
        render :new, status: :unprocessable_entity
      end
    end

    private

    def redirect_if_authenticated
      if current_user
        redirect_to client_dashboard_path, notice: "Vous êtes déjà connecté."
      end
    end

    def registration_params
      params.require(:user).permit(
        :first_name,
        :last_name,
        :phone_number,
        :country_code,
        :email_address,
        :password,
        :password_confirmation
      )
    end
  end
end
