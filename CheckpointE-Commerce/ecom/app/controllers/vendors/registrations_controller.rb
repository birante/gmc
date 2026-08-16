module Vendors
  class RegistrationsController < ApplicationController
    layout "vendor_onboarding", only: [ :new, :create ]
    before_action :redirect_if_authenticated, only: [ :new, :create ]

    def new
      @vendor = Vendor.new
    end

    def create
      Rails.logger.info("🎫 [Vendors::RegistrationsController] Tentative d'inscription vendor - email: #{vendor_params[:email]}")
      result = Vendors::RegistrationService.create(vendor_params)
      if result.success
        Rails.logger.info("✅ [Vendors::RegistrationsController] Inscription vendor réussie (pending) - pending_id: #{result.pending_registration.id}, email: #{result.pending_registration.email}")
        session[:pending_registration_id] = result.pending_registration.id
        session[:pending_registration_type] = "Vendor"
        redirect_to new_vendors_verification_path,
                    notice: "Inscription reçue. Vérifiez votre téléphone pour le code OTP."
      else
        Rails.logger.warn("⚠️ [Vendors::RegistrationsController] Échec inscription vendor - erreurs: #{result.errors.inspect}")

        # Gérer les erreurs de manière flexible (Array ou ActiveModel::Errors)
        error_messages = if result.errors.respond_to?(:full_messages)
          result.errors.full_messages.join(", ")
        else
          Array(result.errors).join(", ")
        end

        @vendor = result.vendor || Vendor.new(vendor_params)
        flash.now[:alert] = error_messages
        render :new, status: :unprocessable_entity
      end
    end

    def dashboard
      @vendor = Vendor.find_by(id: session[:vendor_id]) || Vendor.find_by(id: params[:vendor_id])
      unless @vendor
        redirect_to new_vendors_registration_path, alert: "Vous devez d'abord vous inscrire / vérifier votre compte"
        return
      end

      @shops = @vendor.shops.order(created_at: :desc)
    end

    private

    # Remplacer l'authentification utilisateur pour permettre l'accès
    def require_authentication
      # Ne rien faire - l'inscription vendor est publique
    end

    def redirect_if_authenticated
      if current_vendor
        redirect_to vendors_dashboard_path, notice: "Vous êtes déjà connecté."
      end
    end

    def vendor_params
      params.require(:vendor).permit(:first_name, :last_name, :phone_number, :country_code, :email, :password, :password_confirmation)
    end
  end
end
