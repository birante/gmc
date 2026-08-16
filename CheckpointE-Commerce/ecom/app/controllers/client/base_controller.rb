module Client
  class BaseController < ApplicationController
    layout "client"
    before_action :authenticate_client!
    before_action :require_verified_account!

    private

    def authenticate_client!
      sessionable = Current.session&.sessionable

      unless sessionable.is_a?(User)
        if sessionable.is_a?(Vendor)
          redirect_to vendors_dashboard_path, alert: "Les vendeurs ne peuvent pas accéder à cette page."
        else
          # Sauvegarder l'URL de retour pour rediriger après connexion
          session[:return_to] = request.url
          redirect_to new_client_session_path, alert: "Vous devez vous connecter pour accéder à cette page."
        end
        nil
      end
    end

    def require_verified_account!
      user = current_user
      return unless user

      unless user.verified?
        Rails.logger.warn("⚠️ [Client::BaseController] Tentative d'accès avec compte non vérifié - user_id: #{user.id}")
        # Sauvegarder l'URL de retour pour rediriger après vérification
        session[:return_to_after_verification] = request.url
        # Stocker les infos pour la page de vérification
        session[:pending_verification_email] = user.email_address if user.email_address.present?
        session[:pending_verification_phone] = user.phone_number if user.phone_number.present?
        # Envoi explicite du code (idempotent : ne renvoie pas si un code actif existe déjà).
        # Remplace l'ancien auto-envoi sur le GET de la page de vérification.
        Clients::VerificationCodeSender.call(user)
        redirect_to new_client_verification_path, alert: "Vous devez vérifier votre compte avant de continuer."
        nil
      end
    end

    def current_user
      sessionable = Current.session&.sessionable
      sessionable.is_a?(User) ? sessionable : nil
    end
    helper_method :current_user
  end
end
