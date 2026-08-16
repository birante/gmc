# frozen_string_literal: true

module Sms
  module Providers
    # Orange Sénégal - Orange SMS Pro
    # API: https://api.orangesmspro.sn:8443/api/json
    # Authentification: token + key (HMAC-SHA1 de token + body + timestamp avec clé privée)
    class OrangeSnService
      ORANGE_SN_API_URL = ENV.fetch("ORANGE_SN_API_URL", "https://api.orangesmspro.sn:8443")
      ORANGE_SN_TOKEN = ENV.fetch("ORANGE_SN_TOKEN", "")
      ORANGE_SN_PRIVATE_KEY = ENV.fetch("ORANGE_SN_PRIVATE_KEY",
                                        "")
      ORANGE_SN_SIGNATURE = ENV.fetch("ORANGE_SN_SIGNATURE", "")
      ORANGE_SN_SUBJECT = ENV.fetch("ORANGE_SN_SUBJECT", "sms")

      def initialize
        @connection = Faraday.new(
          url: ORANGE_SN_API_URL,
          headers: { "Content-Type" => "application/json" }
        )
      end

      # Sms::Providers::OrangeSnService.new.send(to: "221776857298", message: "Hello !")
      def send(to:, message:)
        Rails.logger.info("OrangeSnService#send - To: #{to}, Message length: #{message&.length || 0}")

        timestamp = Time.now.to_i
        body = build_body(to: to, message: message)
        key = build_public_key(body, timestamp)

        uri = "/api/json?token=#{CGI.escape(ORANGE_SN_TOKEN)}&key=#{CGI.escape(key)}&timestamp=#{timestamp}"

        response = @connection.post(uri) do |req|
          req.body = body.to_json
        end

        Rails.logger.info("OrangeSnService#send - Response status: #{response.status}")
        handle_response(response)
      rescue StandardError => e
        Rails.logger.error("OrangeSnService#send - Error: #{e.class.name} - #{e.message}")
        Rails.logger.error("OrangeSnService#send - Backtrace: #{e.backtrace.first(5).join("\n")}")
        raise
      end

      private

      def build_body(to:, message:)
        {
          messages: [
            {
              signature: ORANGE_SN_SIGNATURE,
              subject: ORANGE_SN_SUBJECT,
              content: message,
              recipients: [
                { id: "1", value: normalize_phone(to) }
              ]
            }
          ]
        }
      end

      # Clé publique = HMAC-SHA1(token + body_json + timestamp, clé_privée)
      def build_public_key(body_json, timestamp)
        chaine = ORANGE_SN_TOKEN + body_json.to_json + timestamp.to_s
        OpenSSL::HMAC.hexdigest("SHA1", ORANGE_SN_PRIVATE_KEY, chaine)
      end

      def normalize_phone(phone)
        phone.to_s.gsub(/\D/, "").then { |p| p.start_with?("221") ? p : "221#{p}" }
      end

      def handle_response(response)
        body = response.body
        parsed = begin
          JSON.parse(body)
        rescue JSON::ParserError
          nil
        end

        if response.success?
          Rails.logger.info("OrangeSnService - SMS envoyé avec succès. STATUS_TEXT: #{parsed&.dig('STATUS_TEXT') || response.status}")
        else
          status_code = parsed&.dig("STATUS_CODE") || response.status
          status_text = parsed&.dig("STATUS_TEXT") || body
          Rails.logger.error("OrangeSnService - Erreur envoi SMS. STATUS_CODE: #{status_code}, STATUS_TEXT: #{status_text}")
          raise "Orange SMS Pro error: #{status_code} - #{status_text}"
        end
      end
    end
  end
end
