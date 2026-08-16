# frozen_string_literal: true

module Whatsapp
  # Service principal pour envoyer des messages WhatsApp
  class WhatsappService
    SEND_WHATSAPP_ENABLED = ENV.fetch("SEND_WHATSAPP_ENABLED", "false")
    DEFAULT_PROVIDER = ENV.fetch("WHATSAPP_PROVIDER", "meta_cloud_api")

    class ProviderNotFoundError < StandardError; end
    class WhatsappDisabledError < StandardError; end

    # Envoie un message WhatsApp via le provider configuré
    # @param to [String] Numéro de téléphone du destinataire
    # @param message [String] Contenu du message
    # @param template_name [String] Nom du template (optionnel)
    # @param template_params [Array] Paramètres du template (optionnel)
    # @param provider [String] Provider à utiliser (optionnel)
    # @return [Hash] Résultat de l'envoi
    def send_message(to:, message:, template_name: nil, template_params: [], provider: nil)
      Rails.logger.info("WhatsAppService#send_message - To: #{to}, Template: #{template_name}, Message length: #{message&.length || 0}")

      unless SEND_WHATSAPP_ENABLED == "true"
        Rails.logger.info("WhatsAppService#send_message - WhatsApp sending disabled, skipping")
        raise WhatsappDisabledError, "L'envoi de WhatsApp est désactivé"
      end

      provider_name = provider || DEFAULT_PROVIDER
      whatsapp_provider = get_provider(provider_name)

      begin
        result = whatsapp_provider.send(
          to: to,
          message: message,
          template_name: template_name,
          template_params: template_params
        )

        if result[:success]
          Rails.logger.info("WhatsAppService#send_message - Message envoyé avec succès")
        else
          Rails.logger.error("WhatsAppService#send_message - Échec envoi: #{result[:message]}")
        end

        result
      rescue StandardError => e
        Rails.logger.error("WhatsAppService#send_message - Erreur: #{e.class.name} - #{e.message}")
        Rails.logger.error("WhatsAppService#send_message - Backtrace: #{e.backtrace.first(5).join("\n")}")
        raise
      end
    end

    # Vérifie les crédits disponibles pour le provider configuré
    # @param provider [String] Provider à utiliser (optionnel)
    # @return [Hash] Informations sur les crédits
    def check_credits(provider: nil)
      provider_name = provider || DEFAULT_PROVIDER
      whatsapp_provider = get_provider(provider_name)

      whatsapp_provider.credits
    rescue StandardError => e
      Rails.logger.error("WhatsAppService#check_credits - Error: #{e.class.name} - #{e.message}")
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
    # @return [Whatsapp::Providers::BaseProvider] Instance du provider
    def get_provider(provider_name)
      case provider_name.to_s.downcase
      when "meta_cloud_api", "meta"
        Providers::MetaCloudApi.new
      else
        raise ProviderNotFoundError, "Provider WhatsApp '#{provider_name}' non trouvé. Providers disponibles: meta_cloud_api"
      end
    end
  end
end
