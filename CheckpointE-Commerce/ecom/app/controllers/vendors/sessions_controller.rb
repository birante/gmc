module Vendors
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: [ :new, :create, :destroy ]
    layout "vendor_onboarding", only: [ :new, :create ]

    def new
    end

    def create
      identifier = params[:phone_number].presence || params[:email].presence
      normalized_phone_number = params[:phone_number].to_s.gsub(/\D/, "")
      Rails.logger.info("[Vendors::SessionsController] Tentative de connexion vendor - identifier: #{identifier}")

      vendor = if params[:email].present? && params[:phone_number].blank?
        Vendor.find_by(email: params[:email].to_s.strip.downcase)
      else
        Vendor.find_by(phone_number: normalized_phone_number)
      end

      if vendor&.authenticate(params[:password])
        Rails.logger.info("[Vendors::SessionsController] Connexion vendor reussie - vendor_id: #{vendor.id}")
        # Terminer toute session client existante
        if Current.session
          Rails.logger.debug("[Vendors::SessionsController] Terminaison de la session client existante")
          Current.session.destroy
          cookies.delete(:session_id)
        end

        # Create a proper Session model record
        start_new_session_for(vendor)
        session[:vendor_id] = vendor.id

        # Verifier si le compte est verifie
        unless vendor.verified?
          Rails.logger.info("[Vendors::SessionsController] Compte vendor non verifie - vendor_id: #{vendor.id}")

          # Generer un code OTP pour la verification
          config = Rails.application.config.vendor_otp
          otp_code = Otp::Generator.generate_from_config(config)
          ttl = Otp::Generator.ttl_from_config(config)
          ttl_minutes = (ttl / 60).to_i

          # La verification vendeur en connexion se fait par SMS sur le numero de telephone
          channel = "sms"

          # Creer ou mettre a jour le pending registration
          pending = PendingRegistration.find_or_initialize_by(
            user_type: "Vendor",
            email: vendor.email
          )
          pending.update!(
            phone_number: vendor.phone_number,
            otp_code: otp_code,
            otp_expires_at: Time.current + ttl,
            channel: channel,
            encrypted_data: { vendor_id: vendor.id }.to_json,
            verified_at: nil
          )

          # Afficher le code OTP uniquement en developpement (SECURITE: ne jamais logger en production)
          if Rails.env.development?
            Rails.logger.info("[DEV ONLY] CODE OTP VENDOR: #{otp_code} - Channel: #{channel} - TTL: #{ttl_minutes}min")
            puts "\n" + "=" * 50
            puts "[DEV] CODE OTP VENDOR (login): #{otp_code}"
            puts "[DEV] Email: #{vendor.email}" if vendor.email.present?
            puts "[DEV] Telephone: #{vendor.phone_number}" if vendor.phone_number.present?
            puts "[DEV] Canal: #{channel} - Valide: #{ttl_minutes} minutes"
            puts "=" * 50 + "\n"
          else
            Rails.logger.info("[Vendors::SessionsController] OTP genere et envoye - channel: #{channel}")
          end

          # Envoyer l'OTP par le canal approprie
          if channel == "sms"
            Otp::SenderService.send_sms(vendor.phone_number, otp_code, country_code: vendor.country_code)
          else
            Otp::SenderService.send_email(vendor.email, otp_code)
          end

          # Sauvegarder l'URL de retour pour rediriger apres verification
          session[:return_to_after_verification] = vendor.shops.empty? ? new_vendors_shop_path : vendors_dashboard_path
          session[:pending_registration_id] = pending.id
          session[:pending_registration_type] = "Vendor"
          session[:pending_verification_email] = vendor.email if vendor.email.present?

          redirect_to new_vendors_verification_path, alert: "Vous devez verifier votre compte avant de continuer."
          return
        end

        # Verifier si le vendor a une boutique
        if vendor.shops.empty?
          Rails.logger.info("[Vendors::SessionsController] Vendor verifie sans boutique - vendor_id: #{vendor.id}")
          redirect_to new_vendors_shop_path, alert: "Vous devez creer une boutique avant de continuer."
          return
        end

        redirect_to vendors_dashboard_path, notice: t("vendors.sessions.create.success")
      else
        Rails.logger.warn("[Vendors::SessionsController] Echec connexion vendor - identifier: #{identifier.presence || 'N/A'}, phone: #{normalized_phone_number.presence || 'N/A'}")
        flash.now[:alert] = t("vendors.sessions.create.failure")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      vendor_id = session[:vendor_id]
      Rails.logger.info("[Vendors::SessionsController] Deconnexion vendor - vendor_id: #{vendor_id}")
      # Terminer la session ActiveRecord si elle existe
      terminate_session if Current.session

      # Supprimer aussi session[:vendor_id] pour compatibilité
      session.delete(:vendor_id)

      redirect_to root_path, notice: t("vendors.sessions.destroy.success")
    end

    private

    # Remplacer l'authentification utilisateur pour permettre l'accès
    def require_authentication
      # Ne rien faire - les sessions vendors sont publiques
    end
  end
end
