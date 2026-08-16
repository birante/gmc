module PaymentServices
  class SubscriptionPaydunyaHttpService
    include HTTParty

    Result = Struct.new(:success?, :subscription_payment, :redirect_url, :token, :errors, keyword_init: true)

    def initialize(subscription_payment:, shop:, plan:)
      @subscription_payment = subscription_payment
      @shop = shop
      @plan = plan
      @vendor = shop.vendor
      @errors = []

      # Configuration depuis ENV avec valeurs par defaut
      @master_key = ENV.fetch("PAYDUNYA_MASTER_KEY", "qmR4BzHY-Pxvj-C89u-8B0G-4MdkKeygwCIe")
      @private_key = ENV.fetch("PAYDUNYA_PRIVATE_KEY", "test_private_Oswl7zByAb3CcrKwKKl1PChnZ9L")
      @token = ENV.fetch("PAYDUNYA_TOKEN", "ZIZYuDDbEOvVRYeSbUUp")
      @mode = ENV.fetch("PAYDUNYA_MODE", "test")

      # Endpoints
      @base_url = @mode == "live" ? "https://app.paydunya.com/api/v1" : "https://app.paydunya.com/sandbox-api/v1"
    end

    # Cree une invoice avec redirection (PAR - Paiement Avec Redirection)
    def create_checkout_invoice
      Rails.logger.info("[PayDunya Subscription HTTP] Creation invoice - shop_id: #{@shop.id}, plan: #{@plan.code}, montant: #{@subscription_payment.amount}")

      # Construire le payload selon la documentation PayDunya
      payload = build_invoice_payload

      Rails.logger.debug("[PayDunya Subscription HTTP] Payload: #{payload.to_json}")

      # Faire la requete HTTP POST
      response = self.class.post(
        "#{@base_url}/checkout-invoice/create",
        headers: headers,
        body: payload.to_json,
        timeout: 30
      )

      Rails.logger.info("[PayDunya Subscription HTTP] Reponse: #{response.code} - #{response.body}")

      if response.success? && response.parsed_response["response_code"] == "00"
        handle_success_response(response.parsed_response)
      else
        handle_error_response(response.parsed_response)
      end

    rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("[PayDunya Subscription HTTP] Erreur reseau: #{e.class} - #{e.message}")
      @errors << "Erreur de connexion a PayDunya. Veuillez reessayer."
      failure_result
    rescue StandardError => e
      Rails.logger.error("[PayDunya Subscription HTTP] Erreur inattendue: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @errors << "Une erreur inattendue est survenue lors de l'initialisation du paiement."
      failure_result
    end

    # Verifie le statut d'un paiement
    def check_payment_status
      Rails.logger.info("[PayDunya Subscription HTTP] Verification statut - token: #{@subscription_payment.paydunya_token}")

      return Result.new(success?: false, subscription_payment: @subscription_payment, errors: [ "Token PayDunya manquant" ]) unless @subscription_payment.paydunya_token.present?

      response = self.class.get(
        "#{@base_url}/checkout-invoice/confirm/#{@subscription_payment.paydunya_token}",
        headers: headers,
        timeout: 30
      )

      Rails.logger.info("[PayDunya Subscription HTTP] Reponse confirmation: #{response.code} - #{response.body}")

      if response.success? && response.parsed_response["response_code"] == "00"
        status = response.parsed_response["status"]&.downcase

        if status == "completed" || status == "success"
          Rails.logger.info("[PayDunya Subscription HTTP] Paiement complete - token: #{@subscription_payment.paydunya_token}")

          @subscription_payment.update!(
            status: "completed",
            paid_at: Time.current,
            provider_response: {
              status: status,
              verified_at: Time.current,
              response_code: response.parsed_response["response_code"],
              customer: response.parsed_response["customer"]
            }
          )

          Result.new(
            success?: true,
            subscription_payment: @subscription_payment,
            errors: []
          )
        else
          Rails.logger.warn("[PayDunya Subscription HTTP] Paiement non complete - status: #{status}")
          Result.new(
            success?: false,
            subscription_payment: @subscription_payment,
            errors: [ "Paiement non encore confirme (statut: #{status})" ]
          )
        end
      else
        error_text = response.parsed_response&.dig("response_text") || "Token invalide"
        Rails.logger.warn("[PayDunya Subscription HTTP] Echec confirmation - #{error_text}")
        Result.new(
          success?: false,
          subscription_payment: @subscription_payment,
          errors: [ "Impossible de verifier le statut du paiement: #{error_text}" ]
        )
      end

    rescue StandardError => e
      Rails.logger.error("[PayDunya Subscription HTTP] Erreur verification - #{e.class}: #{e.message}")
      Result.new(
        success?: false,
        subscription_payment: @subscription_payment,
        errors: [ "Erreur lors de la verification du paiement: #{e.message}" ]
      )
    end

    private

    def headers
      {
        "Content-Type" => "application/json",
        "PAYDUNYA-MASTER-KEY" => @master_key,
        "PAYDUNYA-PRIVATE-KEY" => @private_key,
        "PAYDUNYA-TOKEN" => @token
      }
    end

    def build_invoice_payload
      {
        invoice: {
          items: build_items,
          taxes: {},
          total_amount: @subscription_payment.amount.to_f,
          description: "Abonnement #{@plan.name} - Boutique: #{@shop.name}"
        },
        store: build_store,
        custom_data: build_custom_data,
        actions: build_actions
      }
    end

    def build_items
      {
        "item_0" => {
          name: "Abonnement #{@plan.name}",
          quantity: 1,
          unit_price: @subscription_payment.amount.to_f.to_s,
          total_price: @subscription_payment.amount.to_f.to_s,
          description: "Abonnement #{@plan.billing_period_months || 12} mois - #{@plan.code}"
        }
      }
    end

    def build_store
      {
        name: ENV.fetch("PAYDUNYA_STORE_NAME", "aa"),
        tagline: ENV.fetch("PAYDUNYA_STORE_TAGLINE", "Votre marketplace en ligne"),
        postal_address: ENV.fetch("PAYDUNYA_STORE_ADDRESS", "Dakar, Senegal"),
        phone: ENV.fetch("PAYDUNYA_STORE_PHONE", "+221776857298"),
        logo_url: ENV.fetch("PAYDUNYA_STORE_LOGO", ""),
        website_url: ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
      }
    end

    def build_custom_data
      {
        shop_id: @shop.id,
        plan_id: @plan.id,
        subscription_payment_id: @subscription_payment.id,
        vendor_id: @vendor.id,
        payment_type: "subscription",
        withdraw_mode: @subscription_payment.withdraw_mode
      }
    end

    def build_actions
      base_url = ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
      locale = I18n.locale.to_s
      {
        cancel_url: "#{base_url}/#{locale}/vendors/paydunya/subscription_cancel",
        return_url: "#{base_url}/#{locale}/vendors/paydunya/subscription_success",
        callback_url: "#{base_url}/#{locale}/vendors/paydunya/subscription_ipn"
      }
    end

    def handle_success_response(response_data)
      token = response_data["token"]
      redirect_url = response_data["response_text"]

      Rails.logger.info("[PayDunya Subscription HTTP] Invoice creee - token: #{token}, url: #{redirect_url}")

      # Mettre a jour le paiement
      @subscription_payment.update!(
        paydunya_token: token,
        paydunya_invoice_url: redirect_url,
        status: "processing",
        provider_response: {
          response_code: response_data["response_code"],
          response_text: response_data["response_text"],
          description: response_data["description"],
          created_at: Time.current
        }
      )

      Result.new(
        success?: true,
        subscription_payment: @subscription_payment,
        redirect_url: redirect_url,
        token: token,
        errors: []
      )
    end

    def handle_error_response(response_data)
      error_text = response_data&.dig("response_text") || "Erreur inconnue"

      Rails.logger.error("[PayDunya Subscription HTTP] Echec creation invoice - #{error_text}")

      error_message = case error_text
      when /Invalid.*[Mm]asterkey/i
        "Configuration PayDunya invalide. Veuillez contacter l'administrateur."
      when /Invalid.*key/i
        "Cles API PayDunya invalides. Veuillez contacter l'administrateur."
      else
        "Erreur PayDunya: #{error_text}"
      end

      @subscription_payment.update(
        status: "failed",
        failure_reason: error_message
      )

      @errors << error_message
      failure_result
    end

    def failure_result
      Result.new(
        success?: false,
        subscription_payment: @subscription_payment,
        redirect_url: nil,
        token: nil,
        errors: @errors
      )
    end
  end
end
