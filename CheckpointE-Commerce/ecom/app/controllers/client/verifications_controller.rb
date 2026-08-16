# frozen_string_literal: true

module Client
  class VerificationsController < ApplicationController
    allow_unauthenticated_access
    layout "client_onboarding", only: [ :new, :create ]

    def new
      @pending_registration_id = session[:pending_registration_id]
      @pending_registration_type = session[:pending_registration_type]

      # Si on a une inscription en attente, récupérer les infos pour l'affichage
      if @pending_registration_id.present?
        @pending_registration = PendingRegistration.find_by(id: @pending_registration_id)
        if @pending_registration
          Rails.logger.info("📱 [Client::VerificationsController] Inscription en attente trouvée - pending_id: #{@pending_registration.id}, email: #{@pending_registration.email}, phone: #{@pending_registration.phone_number}")
          @pending_email = @pending_registration.email
          @pending_phone = @pending_registration.phone_number
        else
          Rails.logger.warn("⚠️ [Client::VerificationsController] Inscription en attente introuvable - pending_id: #{@pending_registration_id}")
          session.delete(:pending_registration_id)
          session.delete(:pending_registration_type)
        end
      end

      # NB: on N'ENVOIE PLUS de code ici. Un GET ne doit pas avoir d'effet de bord
      # (rechargement / prefetch / double-tap = doubles SMS). Le code est envoyé
      # explicitement par les actions qui redirigent vers cette page (inscription,
      # login, require_verified_account!) ou via le bouton « renvoyer » (resend).
    end

    def resend
      Rails.logger.info("🔄 [Client::VerificationsController] Demande de renvoi de code - params: #{params.inspect}")

      # Cas 1: Utilisateur connecté non vérifié
      if current_user && !current_user.verified?
        Rails.logger.info("🔄 [Client::VerificationsController] Renvoi pour utilisateur connecté - user_id: #{current_user.id}")
        Clients::VerificationCodeSender.call(current_user, force: true)
        flash[:notice] = t("client.verifications.resend.success", channel: "SMS")
        redirect_to new_client_verification_path and return
      end

      # Cas 2: Inscription en attente
      pending_registration_id = session[:pending_registration_id]
      unless pending_registration_id
        Rails.logger.warn("⚠️ [Client::VerificationsController] Pas d'inscription en attente en session et pas d'utilisateur connecté")
        flash[:alert] = t("client.verifications.resend.user_not_found")
        redirect_to new_client_verification_path and return
      end

      pending_registration = PendingRegistration.find_by(id: pending_registration_id)
      unless pending_registration
        Rails.logger.warn("⚠️ [Client::VerificationsController] Inscription en attente introuvable - pending_id: #{pending_registration_id}")
        session.delete(:pending_registration_id)
        session.delete(:pending_registration_type)
        flash[:alert] = t("client.verifications.resend.user_not_found")
        redirect_to new_client_verification_path and return
      end

      Rails.logger.info("🔄 [Client::VerificationsController] Inscription en attente trouvée pour renvoi - pending_id: #{pending_registration.id}, email: #{pending_registration.email}, phone: #{pending_registration.phone_number}")

      # Générer un nouveau code OTP
      config = Rails.application.config.user_otp
      new_code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)
      pending_registration.update!(
        otp_code: new_code,
        otp_expires_at: Time.current + ttl
      )

      # Envoyer le nouveau code
      channel = pending_registration.channel
      if channel == "sms" && pending_registration.phone_number.present?
        Otp::SenderService.send_sms(pending_registration.phone_number, new_code)
        Rails.logger.info("✅ [Client::VerificationsController] Code renvoyé par SMS - pending_id: #{pending_registration.id}")
        flash[:notice] = t("client.verifications.resend.success", channel: "SMS")
      elsif channel == "email" && pending_registration.email.present?
        Otp::SenderService.send_email(pending_registration.email, new_code)
        Rails.logger.info("✅ [Client::VerificationsController] Code renvoyé par email - pending_id: #{pending_registration.id}")
        flash[:notice] = t("client.verifications.resend.success", channel: "email")
      else
        Rails.logger.error("❌ [Client::VerificationsController] Échec renvoi de code - pending_id: #{pending_registration.id}, channel: #{channel}")
        flash[:alert] = t("client.verifications.resend.error", error: "Canal de communication non disponible")
      end

      redirect_to new_client_verification_path
    end

    def create
      Rails.logger.info("🔐 [Client::VerificationsController] Tentative de vérification")

      # Combiner les champs OTP individuels
      code = if params[:code].present?
        params[:code].to_s.strip
      else
        # Combiner les champs individuels otp_code_0, otp_code_1, etc.
        (0..3).map { |i| params["otp_code_#{i}"] }.compact.join("").strip
      end

      # FLUX 1: Utilisateur connecté non vérifié (vérification après login)
      if current_user && !current_user.verified?
        Rails.logger.info("🔐 [Client::VerificationsController] Vérification pour utilisateur connecté - user_id: #{current_user.id}, code: #{code}")
        return verify_for_logged_in_user(current_user, code)
      end

      # FLUX 2: Inscription en attente (vérification lors de l'inscription)
      pending_registration_id = session[:pending_registration_id]
      unless pending_registration_id
        Rails.logger.warn("⚠️ [Client::VerificationsController] Pas d'inscription en attente en session et utilisateur non connecté")
        flash.now[:alert] = t("client.verifications.create.user_not_found")
        @pending_registration_id = nil
        return render :new, status: :unprocessable_entity
      end

      Rails.logger.info("🔐 [Client::VerificationsController] Code reçu pour inscription - code: #{code}, pending_id: #{pending_registration_id}")
      result = Clients::RegistrationService.verify(pending_registration_id, code)
      if result.success
        user = result.user
        Rails.logger.info("✅ [Client::VerificationsController] Vérification réussie et compte créé - user_id: #{user.id}, email: #{user.email_address}")

        # Terminer toute session vendor existante
        session.delete(:vendor_id)

        # Créer une session pour l'utilisateur nouvellement créé
        start_new_session_for(user)
        current_cart # déclenche la fusion du panier invité si nécessaire
        session.delete(:pending_registration_id)
        session.delete(:pending_registration_type)

        # Rediriger vers la page d'origine ou le catalogue
        return_path = session.delete(:return_to_after_verification) || client_items_path
        redirect_to return_path, notice: t("client.verifications.create.success"), status: :see_other
      else
        Rails.logger.warn("⚠️ [Client::VerificationsController] Échec vérification - pending_id: #{pending_registration_id}, code: #{code}, errors: #{result.errors.inspect}")

        # Gérer les erreurs de manière flexible (Array ou ActiveModel::Errors)
        errors_array = if result.errors.respond_to?(:full_messages)
          result.errors.full_messages
        else
          Array(result.errors)
        end

        error_message = if errors_array.include?("invalid_code") || errors_array.any? { |e| e.include?("invalid") }
          t("client.verifications.create.invalid_code")
        elsif errors_array.include?("code_expired") || errors_array.any? { |e| e.include?("expired") }
          t("client.verifications.create.invalid_code")
        elsif errors_array.include?("pending_registration_not_found") || errors_array.any? { |e| e.include?("not found") }
          t("client.verifications.create.user_not_found")
        else
          t("client.verifications.create.error")
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

    def verify_for_logged_in_user(user, code)
      Rails.logger.info("🔐 [Client::VerificationsController] Vérification du code pour utilisateur connecté - user_id: #{user.id}")

      # Chercher une vérification active avec ce code
      verification = user.user_verifications.active.find_by(code: code)

      unless verification
        Rails.logger.warn("⚠️ [Client::VerificationsController] Vérification invalide - user_id: #{user.id}, code: #{code}")
        flash.now[:alert] = t("client.verifications.create.invalid_code")
        return render :new, status: :unprocessable_entity
      end

      if verification.expired?
        Rails.logger.warn("⚠️ [Client::VerificationsController] Code expiré - user_id: #{user.id}, verification_id: #{verification.id}")
        flash.now[:alert] = t("client.verifications.create.invalid_code")
        return render :new, status: :unprocessable_entity
      end

      # Marquer le code comme utilisé et l'utilisateur comme vérifié
      verification.mark_used!

      Rails.logger.info("✅ [Client::VerificationsController] Utilisateur vérifié avec succès - user_id: #{user.id}")

      # Rediriger vers la page d'origine ou le catalogue
      return_path = session.delete(:return_to_after_verification) || client_items_path
      redirect_to return_path, notice: t("client.verifications.create.success"), status: :see_other
    end

  end
end
