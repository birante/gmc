module Vendors
  class VerificationsController < ApplicationController
    layout "vendor_onboarding", only: [ :new, :create, :show ]
    before_action :redirect_if_authenticated, only: [ :new, :create, :show ]

    def show
      redirect_to new_vendors_verification_path
    end

    def new
      @pending_registration_id = session[:pending_registration_id]
      @pending_registration_type = session[:pending_registration_type]

      # Si on a une inscription en attente, recuperer les infos pour l'affichage
      if @pending_registration_id.present?
        @pending_registration = PendingRegistration.find_by(id: @pending_registration_id)
        if @pending_registration
          Rails.logger.info("[Vendors::VerificationsController] Inscription en attente trouvee - pending_id: #{@pending_registration.id}")
          @pending_email = @pending_registration.email
          @pending_phone = @pending_registration.phone_number
        else
          Rails.logger.warn("[Vendors::VerificationsController] Inscription en attente introuvable - pending_id: #{@pending_registration_id}")
          session.delete(:pending_registration_id)
          session.delete(:pending_registration_type)
        end
      end
    end

    def resend
      Rails.logger.info("[Vendors::VerificationsController] Demande de renvoi de code")

      pending_registration_id = session[:pending_registration_id]
      unless pending_registration_id
        Rails.logger.warn("[Vendors::VerificationsController] Pas d'inscription en attente en session")
        flash[:alert] = "Inscription en attente introuvable"
        redirect_to new_vendors_verification_path and return
      end

      pending_registration = PendingRegistration.find_by(id: pending_registration_id)
      unless pending_registration
        Rails.logger.warn("[Vendors::VerificationsController] Inscription en attente introuvable - pending_id: #{pending_registration_id}")
        session.delete(:pending_registration_id)
        session.delete(:pending_registration_type)
        flash[:alert] = "Inscription en attente introuvable"
        redirect_to new_vendors_verification_path and return
      end

      Rails.logger.info("[Vendors::VerificationsController] Renvoi code - pending_id: #{pending_registration.id}")

      # Generer un nouveau code OTP
      config = Rails.application.config.vendor_otp
      new_code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)
      ttl_minutes = (ttl / 60).to_i
      pending_registration.update!(
        otp_code: new_code,
        otp_expires_at: Time.current + ttl
      )

      # Envoyer le nouveau code
      channel = pending_registration.channel

      # Afficher le code OTP uniquement en developpement (SECURITE: ne jamais logger en production)
      if Rails.env.development?
        Rails.logger.info("[DEV ONLY] CODE OTP VENDOR (resend): #{new_code} - Channel: #{channel} - TTL: #{ttl_minutes}min")
        puts "\n" + "=" * 50
        puts "[DEV] CODE OTP VENDOR (resend): #{new_code}"
        puts "[DEV] Email: #{pending_registration.email}" if pending_registration.email.present?
        puts "[DEV] Telephone: #{pending_registration.phone_number}" if pending_registration.phone_number.present?
        puts "[DEV] Canal: #{channel} - Valide: #{ttl_minutes} minutes"
        puts "=" * 50 + "\n"
      else
        Rails.logger.info("[Vendors::VerificationsController] OTP regenere et envoye - channel: #{channel}")
      end

      if channel == "sms" && pending_registration.phone_number.present?
        Otp::SenderService.send_sms(pending_registration.phone_number, new_code)
        Rails.logger.info("[Vendors::VerificationsController] Code renvoye par SMS - pending_id: #{pending_registration.id}")
        flash[:notice] = "Code renvoye avec succes par SMS"
      elsif channel == "email" && pending_registration.email.present?
        Otp::SenderService.send_email(pending_registration.email, new_code)
        Rails.logger.info("[Vendors::VerificationsController] Code renvoye par email - pending_id: #{pending_registration.id}")
        flash[:notice] = "Code renvoye avec succes par email"
      else
        Rails.logger.error("[Vendors::VerificationsController] Echec renvoi de code - pending_id: #{pending_registration.id}, channel: #{channel}")
        flash[:alert] = "Echec de renvoi du code"
      end

      redirect_to new_vendors_verification_path
    end

    def create
      Rails.logger.info("[Vendors::VerificationsController] Tentative de verification")

      pending_registration_id = session[:pending_registration_id]
      unless pending_registration_id
        Rails.logger.warn("[Vendors::VerificationsController] Pas d'inscription en attente en session")
        flash.now[:alert] = "Inscription en attente introuvable"
        @pending_registration_id = nil
        return render :new, status: :unprocessable_entity
      end

      # Concatener les chiffres du code OTP
      code = [ params[:otp_code_0], params[:otp_code_1], params[:otp_code_2], params[:otp_code_3] ]
              .map(&:to_s)
              .join
              .strip

      Rails.logger.debug("[Vendors::VerificationsController] Code recu - pending_id: #{pending_registration_id}")
      result = Vendors::RegistrationService.verify(pending_registration_id, code)
      if result.success
        vendor = result.vendor
        Rails.logger.info("[Vendors::VerificationsController] Verification reussie - vendor_id: #{vendor.id}")

        # Terminer toute session client existante
        if Current.session
          Current.session.destroy
          cookies.delete(:session_id)
        end

        # Créer une session pour le vendor nouvellement créé
        start_new_session_for(vendor)
        session[:vendor_id] = vendor.id
        session.delete(:pending_registration_id)
        session.delete(:pending_registration_type)

        # Rediriger vers la création de boutique si le vendor n'en a pas
        if vendor.shops.empty?
          return_path = session.delete(:return_to_after_verification) || new_vendors_shop_path
          redirect_to return_path, notice: "Bienvenue ! Créez votre première boutique.", status: :see_other
        else
          return_path = session.delete(:return_to_after_verification) || vendors_dashboard_path
          redirect_to return_path, notice: "Connexion réussie.", status: :see_other
        end
      else
        # SECURITE: Ne pas logger le code OTP soumis
        Rails.logger.warn("[Vendors::VerificationsController] Echec verification - pending_id: #{pending_registration_id}, errors: #{result.errors.inspect}")

        # Gerer les erreurs de maniere flexible (Array ou ActiveModel::Errors)
        errors_array = if result.errors.respond_to?(:full_messages)
          result.errors.full_messages
        else
          Array(result.errors)
        end

        error_message = if errors_array.include?("invalid_code")
          "Code invalide ou expire"
        elsif errors_array.include?("code_expired")
          "Code invalide ou expire"
        elsif errors_array.include?("pending_registration_not_found")
          "Inscription en attente introuvable"
        else
          "Une erreur est survenue lors de la verification"
        end

        flash.now[:alert] = error_message
        @pending_registration_id = session[:pending_registration_id]
        @pending_registration_type = session[:pending_registration_type]

        # Récupérer les infos pour réaffichage
        if @pending_registration_id
          @pending_registration = PendingRegistration.find_by(id: @pending_registration_id)
          if @pending_registration
            @pending_email = @pending_registration.email
            @pending_phone = @pending_registration.phone_number
          end
        end

        render :new, status: :unprocessable_entity
      end
    end

    private

    # Remplacer l'authentification utilisateur pour permettre l'accès
    def require_authentication
      # Ne rien faire - la vérification vendor est publique
    end

    def redirect_if_authenticated
      # Ne rediriger que si le vendor est connecté ET vérifié
      # Si le vendor est connecté mais non vérifié, permettre l'accès à la page de vérification
      if current_vendor&.verified?
        redirect_to vendors_dashboard_path, notice: "Vous êtes déjà connecté."
      end
    end
  end
end
