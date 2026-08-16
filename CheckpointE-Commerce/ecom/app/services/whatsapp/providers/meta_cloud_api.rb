# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "openssl"

module Whatsapp
  module Providers
    # Provider WhatsApp utilisant l'API officielle Meta Business Cloud API
    # Documentation: https://developers.facebook.com/docs/whatsapp/cloud-api
    class MetaCloudApi < BaseProvider
      # Configuration depuis les variables d'environnement
      WHATSAPP_API_URL = ENV.fetch("WHATSAPP_API_URL", "https://graph.facebook.com/v21.0")
      WHATSAPP_PHONE_NUMBER_ID = ENV.fetch("WHATSAPP_PHONE_NUMBER_ID", "")
      WHATSAPP_BUSINESS_ACCOUNT_ID = ENV.fetch("WHATSAPP_BUSINESS_ACCOUNT_ID", "")
      WHATSAPP_ACCESS_TOKEN = ENV.fetch("WHATSAPP_ACCESS_TOKEN", "")
      WHATSAPP_VERIFY_TOKEN = ENV.fetch("WHATSAPP_VERIFY_TOKEN", "")

      def initialize
        @api_url = WHATSAPP_API_URL
        @phone_number_id = WHATSAPP_PHONE_NUMBER_ID
        @business_account_id = WHATSAPP_BUSINESS_ACCOUNT_ID
        @access_token = WHATSAPP_ACCESS_TOKEN
      end

      # Envoie un message WhatsApp
      # L'API Meta Cloud nécessite l'utilisation de templates pour la plupart des messages
      # Sauf pour les messages de conversation (dans les 24h après un message du client)
      # @param to [String] Numéro de téléphone (format international sans +, ex: "221776857298")
      # @param message [String] Contenu du message (texte libre ou template)
      # @param template_name [String] Nom du template approuvé (optionnel)
      # @param template_params [Array] Paramètres du template (optionnel)
      # @return [Hash] Résultat de l'envoi
      def send(to:, message:, template_name: nil, template_params: [])
        Rails.logger.info("Whatsapp::MetaCloudApi#send - To: #{to}, Message length: #{message&.length || 0}, Template: #{template_name}")

        # Valider la configuration
        unless valid_configuration?
          Rails.logger.error("❌ [Whatsapp::MetaCloudApi] Configuration invalide - phone_number_id ou access_token manquant")
          return {
            success: false,
            message: "Configuration WhatsApp invalide",
            provider_response: { error: "missing_configuration" }
          }
        end

        # Formater le numéro (enlever le + si présent, s'assurer qu'il est en format international)
        formatted_to = format_phone_number(to)

        begin
          # Si un template est fourni, utiliser l'API de template
          if template_name.present?
            return send_template_message(formatted_to, template_name, template_params)
          end

          # Sinon, envoyer un message texte libre (nécessite une conversation active dans les 24h)
          send_text_message(formatted_to, message)
        rescue StandardError => e
          Rails.logger.error("❌ [Whatsapp::MetaCloudApi] Erreur envoi: #{e.class.name} - #{e.message}")
          Rails.logger.error("❌ [Whatsapp::MetaCloudApi] Backtrace: #{e.backtrace.first(5).join("\n")}")
          {
            success: false,
            message: e.message,
            provider_response: { error: e.class.name }
          }
        end
      end

      # Vérifie les crédits/disponibilité via l'API Meta
      def credits
        Rails.logger.info("Whatsapp::MetaCloudApi#credits - Vérification crédits")

        unless valid_configuration?
          return {
            success: false,
            message: "Configuration WhatsApp invalide",
            balance: nil,
            currency: nil
          }
        end

        begin
          uri = URI.parse("#{@api_url}/#{@phone_number_id}")
          uri.query = URI.encode_www_form(access_token: @access_token)

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER

          request = Net::HTTP::Get.new(uri.request_uri)
          response = http.request(request)

          if response.is_a?(Net::HTTPSuccess)
            account_info = JSON.parse(response.body)
            Rails.logger.info("✅ [Whatsapp::MetaCloudApi] Informations compte récupérées")
            {
              success: true,
              balance: "N/A", # L'API Meta ne retourne pas directement les crédits
              currency: "N/A",
              provider_response: account_info
            }
          else
            Rails.logger.error("❌ [Whatsapp::MetaCloudApi] Erreur vérification crédits: #{response.code}")
            {
              success: false,
              message: "Erreur lors de la vérification",
              balance: nil,
              currency: nil,
              provider_response: {
                status: response.code,
                body: response.body
              }
            }
          end
        rescue StandardError => e
          Rails.logger.error("❌ [Whatsapp::MetaCloudApi] Erreur vérification crédits: #{e.message}")
          {
            success: false,
            message: e.message,
            balance: nil,
            currency: nil
          }
        end
      end

      private

      # Envoie un message texte libre (nécessite une conversation active)
      def send_text_message(to, message)
        uri = URI.parse("#{@api_url}/#{@phone_number_id}/messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request = Net::HTTP::Post.new(uri.request_uri)
        request["Authorization"] = "Bearer #{@access_token}"
        request["Content-Type"] = "application/json"

        payload = {
          messaging_product: "whatsapp",
          recipient_type: "individual",
          to: to,
          type: "text",
          text: {
            preview_url: false,
            body: message
          }
        }

        request.body = payload.to_json
        response = http.request(request)

        handle_response(response)
      end

      # Envoie un message template (pour messages hors conversation)
      def send_template_message(to, template_name, template_params = [])
        uri = URI.parse("#{@api_url}/#{@phone_number_id}/messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        request = Net::HTTP::Post.new(uri.request_uri)
        request["Authorization"] = "Bearer #{@access_token}"
        request["Content-Type"] = "application/json"

        # Construire les composants du template
        components = []
        if template_params.any?
          components << {
            type: "body",
            parameters: template_params.map { |param|
              { type: "text", text: param.to_s }
            }
          }
        end

        payload = {
          messaging_product: "whatsapp",
          recipient_type: "individual",
          to: to,
          type: "template",
          template: {
            name: template_name,
            language: {
              code: "fr" # Par défaut français, peut être configuré
            }
          }
        }

        payload[:template][:components] = components if components.any?

        request.body = payload.to_json
        response = http.request(request)

        handle_response(response)
      end

      # Gère la réponse de l'API
      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          result = JSON.parse(response.body)
          Rails.logger.info("✅ [Whatsapp::MetaCloudApi] Message envoyé avec succès - message_id: #{result['messages']&.first&.dig('id')}")
          {
            success: true,
            message: "Message WhatsApp envoyé avec succès",
            provider_response: result,
            message_id: result["messages"]&.first&.dig("id")
          }
        else
          error_body = begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            { raw: response.body }
          end
          Rails.logger.error("❌ [Whatsapp::MetaCloudApi] Erreur envoi - Code: #{response.code}, Body: #{error_body}")
          {
            success: false,
            message: "Erreur lors de l'envoi du message WhatsApp",
            provider_response: {
              status: response.code,
              body: error_body
            }
          }
        end
      end

      # Formate le numéro de téléphone pour WhatsApp (format international sans +)
      def format_phone_number(phone)
        # Enlever tous les caractères non numériques sauf le + au début
        cleaned = phone.to_s.gsub(/[^\d+]/, "")
        # Enlever le + si présent
        cleaned = cleaned.gsub(/^\+/, "")
        # S'assurer qu'il commence par l'indicatif pays (ex: 221 pour Sénégal)
        cleaned
      end

      # Vérifie que la configuration est valide
      def valid_configuration?
        @phone_number_id.present? && @access_token.present?
      end
    end
  end
end
