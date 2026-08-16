module PaymentServices
  class PaydunyaHttpService
    include HTTParty

    Result = Struct.new(:success?, :payment, :redirect_url, :token, :errors, keyword_init: true)

    def initialize(payment:, order:, user:)
      @payment = payment
      @order = order
      @user = user
      @errors = []

      # Configuration depuis ENV avec valeurs par défaut
      @master_key = ENV.fetch("PAYDUNYA_MASTER_KEY", "qmR4BzHY-Pxvj-C89u-8B0G-4MdkKeygwCIe")
      @private_key = ENV.fetch("PAYDUNYA_PRIVATE_KEY", "test_private_Oswl7zByAb3CcrKwKKl1PChnZ9L")
      @token = ENV.fetch("PAYDUNYA_TOKEN", "ZIZYuDDbEOvVRYeSbUUp")
      @mode = ENV.fetch("PAYDUNYA_MODE", "test")

      # Endpoints
      @base_url = @mode == "live" ? "https://app.paydunya.com/api/v1" : "https://app.paydunya.com/sandbox-api/v1"
    end

    # Crée une invoice avec redirection (PAR - Paiement Avec Redirection)
    def create_checkout_invoice
      Rails.logger.info("[PayDunya HTTP] Création invoice checkout - order_id: #{@order.id}, montant: #{@payment.amount}")

      # Construire le payload selon la documentation PayDunya
      payload = build_invoice_payload

      # Faire la requête HTTP POST
      response = self.class.post(
        "#{@base_url}/checkout-invoice/create",
        headers: headers,
        body: payload.to_json,
        timeout: 30
      )

      Rails.logger.info("[PayDunya HTTP] Réponse: #{response.code} - #{response.body}")

      if response.success? && response.parsed_response["response_code"] == "00"
        handle_success_response(response.parsed_response)
      else
        handle_error_response(response.parsed_response)
      end

    rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error("[PayDunya HTTP] Erreur réseau: #{e.class} - #{e.message}")
      @errors << "Erreur de connexion à PayDunya. Veuillez réessayer."
      failure_result
    rescue StandardError => e
      Rails.logger.error("[PayDunya HTTP] Erreur inattendue: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @errors << "Une erreur inattendue est survenue lors de l'initialisation du paiement."
      failure_result
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
          taxes: build_taxes,
          customer: build_customer,
          total_amount: @payment.amount.to_f,
          description: "Commande ##{@order.id}"
        },
        store: build_store,
        custom_data: build_custom_data,
        actions: build_actions
      }
    end

    def build_items
      items = {}
      @order.order_items.includes(:item).each_with_index do |order_item, index|
        items["item_#{index}"] = {
          name: order_item.item.name,
          quantity: order_item.quantity,
          unit_price: order_item.unit_price.to_s,
          total_price: order_item.total_price.to_s,
          description: order_item.item.description&.truncate(100) || ""
        }
      end
      items
    end

    def build_taxes
      taxes = {}

      # Ajouter les frais de livraison comme taxe
      if @order.delivery_fee.to_f > 0
        taxes["tax_0"] = {
          name: "Frais de livraison",
          amount: @order.delivery_fee.to_f
        }
      end

      taxes
    end

    def build_customer
      {
        name: @user.full_name,
        email: @user.email_address || "",
        phone: @user.formatted_phone_number || @user.phone_number
      }
    end

    def build_store
      {
        name: ENV.fetch("PAYDUNYA_STORE_NAME", "aa"),
        tagline: ENV.fetch("PAYDUNYA_STORE_TAGLINE", "Votre marketplace en ligne"),
        postal_address: ENV.fetch("PAYDUNYA_STORE_ADDRESS", "Dakar, Sénégal"),
        phone: ENV.fetch("PAYDUNYA_STORE_PHONE", "+221776857298"),
        logo_url: ENV.fetch("PAYDUNYA_STORE_LOGO", ""),
        website_url: ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
      }
    end

    def build_custom_data
      {
        order_id: @order.id,
        user_id: @user.id,
        payment_id: @payment.id
      }
    end

    def build_actions
      base_url = ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
      {
        cancel_url: "#{base_url}/paydunya/cancel",
        return_url: "#{base_url}/paydunya/success",
        callback_url: "#{base_url}/paydunya/callback"
      }
    end

    def handle_success_response(response_data)
      token = response_data["token"]
      redirect_url = response_data["response_text"]

      Rails.logger.info("[PayDunya HTTP] Invoice créée - token: #{token}, url: #{redirect_url}")

      # Mettre à jour le paiement
      @payment.update!(
        paydunya_token: token,
        paydunya_invoice_url: redirect_url,
        payment_type: "PAR",
        provider_response: {
          response_code: response_data["response_code"],
          response_text: response_data["response_text"],
          description: response_data["description"],
          created_at: Time.current
        }
      )

      Result.new(
        success?: true,
        payment: @payment,
        redirect_url: redirect_url,
        token: token,
        errors: []
      )
    end

    def handle_error_response(response_data)
      error_text = response_data&.dig("response_text") || "Erreur inconnue"

      Rails.logger.error("[PayDunya HTTP] Échec création invoice - #{error_text}")

      error_message = case error_text
      when /Invalid.*[Mm]asterkey/i
        "Configuration PayDunya invalide. Veuillez contacter l'administrateur."
      when /Invalid.*key/i
        "Clés API PayDunya invalides. Veuillez contacter l'administrateur."
      else
        "Erreur PayDunya: #{error_text}"
      end

      @errors << error_message
      failure_result
    end

    def failure_result
      Result.new(
        success?: false,
        payment: @payment,
        redirect_url: nil,
        token: nil,
        errors: @errors
      )
    end
  end
end
