# frozen_string_literal: true

module Clients
  # Génère et envoie un code de vérification (OTP) à un User connecté mais non vérifié.
  #
  # Idempotent par défaut : si un code actif existe déjà, on NE renvoie PAS de SMS
  # (évite les doubles envois). Passer `force: true` pour forcer un nouvel envoi.
  #
  # Appelé explicitement par les flux qui redirigent un user non vérifié vers la
  # page de vérification :
  #   - Client::BaseController#require_verified_account!
  #   - Client::VerificationsController#resend (user connecté)
  #
  # NB: la page de vérification (`Client::VerificationsController#new`) ne déclenche
  # PLUS d'envoi. Un GET ne doit pas avoir d'effet de bord : un rechargement / prefetch
  # / double-tap provoquait deux SMS « en même temps » (le vendor n'a jamais eu ce
  # problème car sa page de vérification n'envoie rien).
  class VerificationCodeSender
    Result = Struct.new(:success, :channel, :error, keyword_init: true)

    def self.call(user, force: false)
      new(user, force: force).call
    end

    def initialize(user, force: false)
      @user = user
      @force = force
    end

    def call
      unless @force
        active = @user.user_verifications.active.order(created_at: :desc).first
        if active
          Rails.logger.info("ℹ️ [Clients::VerificationCodeSender] Code actif déjà existant, pas de renvoi - user_id: #{@user.id}, verification_id: #{active.id}")
          return Result.new(success: true, channel: active.channel)
        end
      end

      send_code
    end

    private

    def send_code
      channel = if @user.phone_number.present?
        "sms"
      elsif @user.email_address.present?
        "email"
      else
        Rails.logger.error("❌ [Clients::VerificationCodeSender] Aucun moyen de contacter l'utilisateur - user_id: #{@user.id}")
        return Result.new(success: false, error: "Aucun moyen de contacter l'utilisateur")
      end

      config = Rails.application.config.user_otp
      code = Otp::Generator.generate_from_config(config)
      ttl = Otp::Generator.ttl_from_config(config)

      verification = @user.user_verifications.create!(
        code: code,
        channel: channel,
        expires_at: Time.current + ttl,
        status: false
      )
      Rails.logger.info("💾 [Clients::VerificationCodeSender] Vérification créée - verification_id: #{verification.id}, channel: #{channel}, user_id: #{@user.id}")

      if channel == "sms"
        notification = Notifications::VerificationCodeNotification.new(
          recipient: @user,
          code: code,
          channel: "sms",
          send_sms: true,
          send_email: true # fallback email si le SMS échoue
        )
        result = notification.deliver

        if result[:sms]&.dig(:success)
          Result.new(success: true, channel: "sms")
        elsif result[:email]&.dig(:success)
          Result.new(success: true, channel: "email")
        else
          error = result[:sms]&.dig(:error) || result[:sms]&.dig(:reason) || "Échec inconnu"
          Rails.logger.error("❌ [Clients::VerificationCodeSender] Échec envoi SMS et email - user_id: #{@user.id}, error: #{error}")
          Result.new(success: false, error: error)
        end
      else
        Notifications::NotificationService.send_verification_code(
          recipient: @user,
          code: code,
          channel: "email",
          send_sms: false,
          send_email: true
        )
        Result.new(success: true, channel: "email")
      end
    rescue => e
      Rails.logger.error("❌ [Clients::VerificationCodeSender] Erreur envoi code - user_id: #{@user.id}, error: #{e.class} #{e.message}")
      Result.new(success: false, error: e.message)
    end
  end
end
