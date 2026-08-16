# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "openssl"

module Sms
  module Providers
    # Provider SMS pour LAM (L'Africamobile)
    #
    # Documentation API: https://developers.lafricamobile.com/docs/sms/
    #
    # Configuration requise (variables d'environnement):
    #   - LAM_API_URL: URL de l'API (défaut: https://lamsms.lafricamobile.com/api)
    #   - LAM_SENDER: Nom de l'expéditeur (ex: "aa")
    #   - LAM_ACCOUNT_ID: ID du compte LAM
    #   - LAM_PASSWORD: Mot de passe du compte LAM
    #   - LAM_RET_ID: ID de retour (optionnel)
    #   - LAM_RET_URL: URL de callback (optionnel)
    #
    # Usage:
    #   provider = Sms::Providers::LamService.new
    #   result = provider.send(to: "221776857298", message: "Votre code: 1234")
    #   if result[:success]
    #     puts "SMS envoyé!"
    #   end
    #
    #   credits = provider.credits
    #   puts "Crédits restants: #{credits[:balance]} #{credits[:currency]}"
    #
    class LamService < BaseProvider
      LAM_API_URL = ENV.fetch("LAM_API_URL", "https://lamsms.lafricamobile.com/api")
      LAM_SENDER = ENV.fetch("LAM_SENDER", "LAM")
      LAM_ACCOUNT_ID = ENV.fetch("LAM_ACCOUNT_ID", "OKEMAMY_01")
      LAM_PASSWORD = ENV.fetch("LAM_PASSWORD", "98qceo66aYDAXUM")
      LAM_RET_ID = ENV.fetch("LAM_RET_ID", "Push_1")
      LAM_RET_URL = ENV.fetch("LAM_RET_URL", "https://aa.okemamy.com/sms/lam_callback")

      def initialize
        @api_uri = URI.parse(LAM_API_URL)
      end

      def sender
        LAM_SENDER
      end

      # Sms::Providers::LamService.new.send(to: "221776857298", message: "Hello !")
      def send(to:, message:)
        start_time = Time.current
        Rails.logger.info("🚀 [LamService] ========== ENVOI VIA LAM API ==========")
        Rails.logger.info("📱 [LamService] Destinataire: #{to} | Message: #{message&.length || 0} chars")
        Rails.logger.info("🔧 [LamService] Config - URL: #{LAM_API_URL} | Sender: #{LAM_SENDER}")
        Rails.logger.info("🔐 [LamService] Credentials - Account: #{LAM_ACCOUNT_ID.present? ? LAM_ACCOUNT_ID : '❌ MANQUANT'} | Password: #{LAM_PASSWORD.present? ? '✅ OK' : '❌ MANQUANT'}")

        begin
          http = Net::HTTP.new(@api_uri.host, @api_uri.port)
          http.use_ssl = @api_uri.scheme == "https"
          # Activer la vérification SSL pour la sécurité
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER if @api_uri.scheme == "https"

          # Utiliser le chemin de l'URI ou "/api" par défaut
          path = @api_uri.path.presence || "/api"
          request = Net::HTTP::Post.new(path)
          request["Content-Type"] = "application/json"

          # Format selon la documentation LAM: https://developers.lafricamobile.com/docs/sms/endpoint/send-via-JSON/send-via-JSON
          # Normaliser d'abord, puis supprimer le préfixe + pour LAM
          normalized_to = PhoneNormalizerService.normalize(to, country_code: "SN")
          unless normalized_to.present?
            raise ArgumentError, "Numéro invalide: #{to}"
          end

          formatted_to = normalized_to.gsub(/^\+/, "")
          Rails.logger.info("🔢 [LamService] Formatage numéro - Input: #{to} -> Normalized: #{normalized_to} -> LAM: #{formatted_to}")

          payload = {
            "accountid" => LAM_ACCOUNT_ID,
            "password" => LAM_PASSWORD,
            "sender" => LAM_SENDER,
            "text" => message,
            "to" => formatted_to
          }

          Rails.logger.info("📦 [LamService] Payload - Account: #{LAM_ACCOUNT_ID} | Sender: #{LAM_SENDER} | To: #{formatted_to} | Length: #{message.length}")

          # Ajouter les champs optionnels s'ils sont définis
          payload["ret_id"] = LAM_RET_ID if LAM_RET_ID.present?
          payload["ret_url"] = LAM_RET_URL if LAM_RET_URL.present?
          payload["priority"] = "2" # Priorité par défaut

          request.body = payload.to_json

          Rails.logger.info("🌐 [LamService] Envoi requête HTTP POST vers #{@api_uri.host}#{path}...")
          http_start = Time.current
          response = http.request(request)
          http_duration = (Time.current - http_start).round(3)

          Rails.logger.info("📡 [LamService] Réponse reçue - Status: #{response.code} | Duration: #{http_duration}s")
          Rails.logger.debug("📄 [LamService] Body: #{response.body}") if Rails.env.development?

          result = handle_response(response)
          total_duration = (Time.current - start_time).round(3)

          if result[:success]
            Rails.logger.info("✅ [LamService] SMS envoyé avec succès en #{total_duration}s")
          else
            Rails.logger.error("❌ [LamService] Échec envoi après #{total_duration}s")
          end

          result
        rescue StandardError => e
          total_duration = (Time.current - start_time).round(3)
          Rails.logger.error("❌ [LamService] EXCEPTION après #{total_duration}s - #{e.class.name}")
          Rails.logger.error("❌ [LamService] Message: #{e.message}")
          Rails.logger.error("❌ [LamService] Backtrace:\n#{e.backtrace.first(5).join("\n")}")
          {
            success: false,
            message: e.message,
            provider_response: { error: e.class.name, details: e.message }
          }
        end
      end

      # Sms::Providers::LamService.new.credits
      def credits
        start_time = Time.current
        Rails.logger.info("🚀 [LamService] Vérification du crédit disponible...")

        begin
          http = Net::HTTP.new(@api_uri.host, @api_uri.port)
          http.use_ssl = @api_uri.scheme == "https"
          # Activer la vérification SSL pour la sécurité
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER if @api_uri.scheme == "https"

          # Credit check endpoint per LAM docs:
          # https://lamsms.lafricamobile.com/credits?accountid=...&password=...
          uri = URI.parse("#{@api_uri.scheme}://#{@api_uri.host}/credits")
          uri.query = URI.encode_www_form(accountid: LAM_ACCOUNT_ID, password: LAM_PASSWORD)

          request = Net::HTTP::Get.new(uri.request_uri)

          http_start = Time.current
          response = http.request(request)

          # Some accounts may require /creditsSend, retry on 404
          if response.code.to_s == "404"
            fallback_uri = URI.parse("#{@api_uri.scheme}://#{@api_uri.host}/creditsSend")
            fallback_uri.query = uri.query
            request = Net::HTTP::Get.new(fallback_uri.request_uri)
            response = http.request(request)
          end
          http_duration = (Time.current - http_start).round(3)

          Rails.logger.info("📡 [LamService] Réponse crédit - Status: #{response.code} | Duration: #{http_duration}s")

          result = handle_credit_response(response)
          total_duration = (Time.current - start_time).round(3)

          if result[:success]
            Rails.logger.info("✅ [LamService] Crédit vérifié en #{total_duration}s - Balance: #{result[:balance]} #{result[:currency]}")
          else
            Rails.logger.error("❌ [LamService] Échec vérification crédit après #{total_duration}s")
          end

          result
        rescue StandardError => e
          total_duration = (Time.current - start_time).round(3)
          Rails.logger.error("❌ [LamService] EXCEPTION après #{total_duration}s - #{e.class.name}")
          Rails.logger.error("❌ [LamService] Message: #{e.message}")
          {
            success: false,
            message: e.message,
            balance: nil,
            currency: nil
          }
        end
      end

      private

      # Traite la réponse HTTP de l'API LAM pour l'envoi de SMS
      # @param response [Net::HTTPResponse] Réponse HTTP
      # @return [Hash] Résultat formaté avec :success, :message, :provider_response
      def handle_response(response)
        if response.is_a?(Net::HTTPSuccess)
          Rails.logger.info("✅ [LamService] Réponse HTTP Success (#{response.code})")

          # LAM retourne soit du JSON, soit un ID de transaction hexadécimal
          provider_response = parse_lam_response(response.body)

          # Vérifier si c'est un succès
          if is_successful_response?(provider_response)
            transaction_id = extract_transaction_id(provider_response)
            Rails.logger.info("📊 [LamService] Transaction ID: #{transaction_id}") if transaction_id.present?
            {
              success: true,
              message: "SMS envoyé avec succès",
              provider_response: provider_response,
              transaction_id: transaction_id
            }
          else
            Rails.logger.error("❌ [LamService] Réponse d'erreur - #{provider_response.inspect}")
            {
              success: false,
              message: extract_error_message(provider_response),
              provider_response: provider_response
            }
          end
        else
          Rails.logger.error("❌ [LamService] HTTP Error - Status: #{response.code}")
          Rails.logger.error("❌ [LamService] Body: #{response.body}")
          {
            success: false,
            message: "Erreur lors de l'envoi du SMS (HTTP #{response.code})",
            provider_response: {
              status: response.code,
              body: response.body
            }
          }
        end
      end

      # Parse la réponse LAM (JSON ou ID de transaction)
      def parse_lam_response(body)
        # Essayer de parser en JSON
        begin
          parsed = JSON.parse(body)
          Rails.logger.info("📊 [LamService] Réponse JSON - Keys: #{parsed.keys.join(', ')}") if parsed.is_a?(Hash)
          parsed
        rescue JSON::ParserError
          # Si ce n'est pas du JSON, vérifier si c'est un ID de transaction hexadécimal
          if body =~ /^[a-f0-9]{12,}$/i
            Rails.logger.info("📊 [LamService] Réponse ID de transaction: #{body}")
            { "transaction_id" => body, "raw" => body }
          else
            Rails.logger.warn("⚠️ [LamService] Réponse non-JSON non reconnue: #{body}")
            { "raw" => body }
          end
        end
      end

      # Vérifie si la réponse LAM indique un succès
      def is_successful_response?(response)
        # Cas 1: JSON avec transaction_id
        return true if response.is_a?(Hash) && (response["transaction_id"].present? || response[:transaction_id].present?)

        # Cas 2: JSON avec status "OK" ou "success"
        return true if response.is_a?(Hash) && response["status"]&.upcase&.include?("OK")
        return true if response.is_a?(Hash) && response[:status]&.to_s&.upcase&.include?("OK")

        # Cas 3: ID de transaction hexadécimal (12+ caractères)
        return true if response.is_a?(Hash) && response["raw"]&.match?(/^[a-f0-9]{12,}$/i)
        return true if response.is_a?(Hash) && response[:raw]&.match?(/^[a-f0-9]{12,}$/i)

        # Cas 4: Erreur explicite
        return false if response.is_a?(Hash) && (
          response["error"].present? ||
          response[:error].present? ||
          response["error_code"].present? ||
          response[:error_code].present? ||
          response["status"]&.upcase&.include?("ERROR") ||
          response[:status]&.to_s&.upcase&.include?("ERROR")
        )

        false
      end

      # Extrait l'ID de transaction de la réponse
      def extract_transaction_id(response)
        return response["transaction_id"] if response.is_a?(Hash) && response["transaction_id"].present?
        return response[:transaction_id] if response.is_a?(Hash) && response[:transaction_id].present?
        return response["raw"] if response.is_a?(Hash) && response["raw"].present?
        return response[:raw] if response.is_a?(Hash) && response[:raw].present?
        nil
      end

      # Extrait le message d'erreur de la réponse
      def extract_error_message(response)
        return response["error"] if response.is_a?(Hash) && response["error"].present?
        return response[:error] if response.is_a?(Hash) && response[:error].present?
        return response["message"] if response.is_a?(Hash) && response["message"].present?
        return response[:message] if response.is_a?(Hash) && response[:message].present?
        return "Crédit insuffisant" if response.is_a?(Hash) && (response["error_code"] == "402" || response[:error_code] == "402")
        "Erreur inconnue lors de l'envoi du SMS"
      end

      # Traite la réponse HTTP de l'API LAM pour vérifier les crédits
      # @param response [Net::HTTPResponse] Réponse HTTP
      # @return [Hash] Résultat avec :success, :balance, :currency, :provider_response
      def handle_credit_response(response)
        if response.is_a?(Net::HTTPSuccess)
          credit_info = parse_credit_response(response.body)
          Rails.logger.info("✅ [LamService] Crédit disponible: #{credit_info['balance']} #{credit_info['currency']}")
          {
            success: true,
            balance: credit_info["balance"],
            currency: credit_info["currency"],
            provider_response: credit_info
          }
        else
          Rails.logger.error("❌ [LamService] Erreur vérification crédit - HTTP #{response.code}")
          Rails.logger.error("❌ [LamService] Body: #{response.body}")
          {
            success: false,
            message: "Erreur lors de la vérification du crédit (HTTP #{response.code})",
            balance: nil,
            currency: nil,
            provider_response: {
              status: response.code,
              body: response.body
            }
          }
        end
      end

      def parse_credit_response(body)
        JSON.parse(body)
      rescue JSON::ParserError
        parse_credit_xml(body)
      end

      def parse_credit_xml(body)
        require "rexml/document"

        doc = REXML::Document.new(body)
        routes = REXML::XPath.match(doc, "//credits/route").map do |route|
          {
            "type" => route.elements["type"]&.text,
            "credits" => route.elements["credits"]&.text,
            "credits_month" => route.elements["credits_month"]&.text
          }
        end

        total_credits = routes.map { |r| r["credits"].to_i }.sum if routes.any?

        {
          "balance" => total_credits,
          "currency" => nil,
          "routes" => routes,
          "raw" => body
        }
      rescue REXML::ParseException
        { "raw" => body }
      end
    end
  end
end
