# frozen_string_literal: true

require_relative "message_validator"

module Sms
  class SmsService
    SEND_SMS_ENABLED = ENV.fetch("SEND_SMS_ENABLED", "true")
    DEFAULT_PROVIDER = ENV.fetch("SMS_PROVIDER", "lam_service")

    class ProviderNotFoundError < StandardError; end
    class SmsDisabledError < StandardError; end

    # Envoie un SMS via le provider configuré
    # @param to [String] Numéro de téléphone du destinataire
    # @param message [String] Contenu du message
    # @param sms_type [String] Type de SMS (verification, notification, alert)
    # @param provider [String] Provider à utiliser (optionnel, utilise le provider par défaut si non spécifié)
    # @param validate_length [Boolean] Valider la longueur du message (défaut: true)
    # @param max_segments [Integer] Nombre maximum de segments autorisés (défaut: 3)
    # @return [SmsMessage] L'enregistrement SMS créé
    def send_sms(to:, message:, sms_type: nil, provider: nil, validate_length: true, max_segments: 3)
      start_time = Time.current
      Rails.logger.info("🚀 [SmsService] ==================== ENVOI SMS ====================")
      Rails.logger.info("📱 [SmsService] Destinataire: #{to} | Type: #{sms_type || 'non-spécifié'}")
      Rails.logger.info("📊 [SmsService] Message: #{message.length} chars | Max segments: #{max_segments}")
      Rails.logger.info("🔧 [SmsService] Provider: #{provider || DEFAULT_PROVIDER} | Validation: #{validate_length}")
      Rails.logger.debug("📝 [SmsService] Contenu: #{message}") if Rails.env.development?

      unless SEND_SMS_ENABLED == "true"
        Rails.logger.warn("⚠️ [SmsService] SMS DÉSACTIVÉ - SEND_SMS_ENABLED=#{SEND_SMS_ENABLED}")
        raise SmsDisabledError, "L'envoi de SMS est désactivé"
      end

      # Valider la longueur du message
      if validate_length
        validation = MessageValidator.validate(message, max_segments: max_segments)
        Rails.logger.info("🔍 [SmsService] Validation - Segments: #{validation[:segments]} | Valid: #{validation[:valid]}")
        if validation[:warning]
          Rails.logger.warn("⚠️ [SmsService] #{validation[:warning]}")
        end
        unless validation[:valid]
          Rails.logger.error("❌ [SmsService] Message trop long - #{validation[:info]}")
          raise MessageValidator::MessageTooLongError, validation[:info]
        end
      end

      provider_name = provider || DEFAULT_PROVIDER
      Rails.logger.info("🔧 [SmsService] Initialisation provider: #{provider_name}")
      sms_provider = get_provider(provider_name)

      begin
        sender = sms_provider.respond_to?(:sender) ? sms_provider.sender : nil
        Rails.logger.info("📝 [SmsService] Création enregistrement SMS - From: #{sender || 'N/A'} | To: #{to}")

        sms_message = SmsMessage.create!(
          from: sender,
          to:,
          body: message,
          status: "sending",
          sms_type:,
          provider: provider_name
        )
        Rails.logger.info("✅ [SmsService] SmsMessage créé - ID: #{sms_message.id} | Status: sending")

        send_start = Time.current
        result = sms_provider.send(to:, message:)
        send_duration = (Time.current - send_start).round(3)

        if result[:success]
          sms_message.update!(
            status: "sent",
            provider_response: result[:provider_response] || {}
          )
          total_duration = (Time.current - start_time).round(3)
          Rails.logger.info("✅ [SmsService] SMS ENVOYÉ - ID: #{sms_message.id} | Provider: #{send_duration}s | Total: #{total_duration}s")
          Rails.logger.info("📊 [SmsService] Response: #{result[:provider_response]&.slice('message_id', 'status')&.to_json}")
        else
          sms_message.update!(
            status: "failed",
            provider_response: result[:provider_response] || { error: result[:message] }
          )
          total_duration = (Time.current - start_time).round(3)
          Rails.logger.error("❌ [SmsService] ÉCHEC ENVOI - ID: #{sms_message.id} | Duration: #{total_duration}s")
          Rails.logger.error("❌ [SmsService] Raison: #{result[:message]}")
        end

        sms_message
      rescue StandardError => e
        total_duration = (Time.current - start_time).round(3)
        sms_message&.update!(
          status: "failed",
          provider_response: { error: e.class.name, message: e.message }
        )
        Rails.logger.error("❌ [SmsService] EXCEPTION après #{total_duration}s - #{e.class.name}")
        Rails.logger.error("❌ [SmsService] Message: #{e.message}")
        Rails.logger.error("❌ [SmsService] Backtrace:\n#{e.backtrace.first(5).join("\n")}")
        raise
      end
    end

    # Vérifie les crédits disponibles pour le provider configuré
    # @param provider [String] Provider à utiliser (optionnel)
    # @return [Hash] Informations sur les crédits
    def check_credits(provider: nil)
      provider_name = provider || DEFAULT_PROVIDER
      sms_provider = get_provider(provider_name)

      sms_provider.credits
    rescue StandardError => e
      Rails.logger.error("SmsService#check_credits - Error: #{e.class.name} - #{e.message}")
      {
        success: false,
        message: e.message,
        balance: nil,
        currency: nil
      }
    end

    private

    # Retourne l'instance du provider demandé
    # @param provider_name [String] Nom du provider
    # @return [Sms::Providers::BaseProvider] Instance du provider
    def get_provider(provider_name)
      case provider_name.to_s.downcase
      when "orange_sn_service", "orange_sn", "orange"
        Providers::OrangeSnService.new
      when "lam_service", "lam"
        Providers::LamService.new
      else
        raise ProviderNotFoundError, "Provider '#{provider_name}' non trouvé. Providers disponibles: #{SmsMessage::PROVIDERS.join(', ')}"
      end
    end
  end
end
