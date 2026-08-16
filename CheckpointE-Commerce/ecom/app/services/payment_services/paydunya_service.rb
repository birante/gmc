module PaymentServices
  class PaydunyaService
    Result = Struct.new(:success?, :payment, :redirect_url, :token, :errors, keyword_init: true)

    def initialize(payment:, order:, user:)
      @payment = payment
      @order = order
      @user = user
      @errors = []
    end

    # Initialise un paiement avec redirection (PAR)
    def create_checkout_invoice
      Rails.logger.info("[PayDunya] Création invoice checkout - order_id: #{@order.id}, montant: #{@payment.amount}")

      invoice = Paydunya::Checkout::Invoice.new

      # Ajouter les articles de la commande
      @order.order_items.includes(:item).each do |order_item|
        invoice.add_item(
          order_item.item.name,
          order_item.quantity,
          order_item.unit_price,
          order_item.total_price,
          order_item.item.description&.truncate(100) || ""
        )
      end

      # Ajouter les frais de livraison comme article
      if @order.delivery_fee.to_f > 0
        invoice.add_item(
          "Frais de livraison",
          1,
          @order.delivery_fee,
          @order.delivery_fee
        )
      end

      # Configurer le montant total
      invoice.total_amount = @payment.amount

      # Ajouter une description
      invoice.description = "Commande ##{@order.id} - #{@user.email_address}"

      # Ajouter des données personnalisées
      invoice.add_custom_data("order_id", @order.id)
      invoice.add_custom_data("user_id", @user.id)
      invoice.add_custom_data("payment_id", @payment.id)

      # URLs de callback dynamiques
      base_url = ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
      Paydunya::Checkout::Store.cancel_url = "#{base_url}/paydunya/cancel"
      Paydunya::Checkout::Store.return_url = "#{base_url}/paydunya/success"

      # Créer la facture
      if invoice.create
        Rails.logger.info("[PayDunya] Invoice créée - token: #{invoice.token}, url: #{invoice.invoice_url}")

        # Mettre à jour le paiement
        @payment.update!(
          paydunya_token: invoice.token,
          paydunya_invoice_url: invoice.invoice_url,
          payment_type: "PAR",
          provider_response: {
            response_code: invoice.response_code,
            response_text: invoice.response_text,
            created_at: Time.current
          }
        )

        Result.new(
          success?: true,
          payment: @payment,
          redirect_url: invoice.invoice_url,
          token: invoice.token,
          errors: []
        )
      else
        Rails.logger.error("[PayDunya] Échec création invoice - #{invoice.response_text}")
        error_message = case invoice.response_text
        when /Invalid Masterkey/i
          "Configuration PayDunya invalide. Veuillez contacter l'administrateur."
        when /Invalid.*key/i
          "Clés API PayDunya invalides. Veuillez contacter l'administrateur."
        else
          "Erreur PayDunya: #{invoice.response_text}"
        end
        @errors << error_message

        Result.new(
          success?: false,
          payment: @payment,
          redirect_url: nil,
          token: nil,
          errors: @errors
        )
      end
    rescue StandardError => e
      Rails.logger.error("[PayDunya] Exception - #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      error_message = if e.message =~ /Invalid.*key/i
        "Configuration PayDunya invalide. Veuillez contacter l'administrateur."
      else
        "Une erreur inattendue s'est produite lors de l'initialisation du paiement"
      end
      @errors << error_message

      Result.new(
        success?: false,
        payment: @payment,
        redirect_url: nil,
        token: nil,
        errors: @errors
      )
    end

    # Initialise un paiement sans redirection (PSR)
    def create_onsite_invoice(customer_phone_or_email)
      Rails.logger.info("[PayDunya] Création invoice onsite - order_id: #{@order.id}, customer: #{customer_phone_or_email}")

      invoice = Paydunya::Onsite::Invoice.new

      # Ajouter les articles de la commande
      @order.order_items.includes(:item).each do |order_item|
        invoice.add_item(
          order_item.item.name,
          order_item.quantity,
          order_item.unit_price,
          order_item.total_price,
          order_item.item.description&.truncate(100) || ""
        )
      end

      # Ajouter les frais de livraison comme article
      if @order.delivery_fee.to_f > 0
        invoice.add_item(
          "Frais de livraison",
          1,
          @order.delivery_fee,
          @order.delivery_fee
        )
      end

      # Configurer le montant total
      invoice.total_amount = @payment.amount

      # Ajouter une description
      invoice.description = "Commande ##{@order.id} - #{@user.email_address}"

      # Ajouter des données personnalisées
      invoice.add_custom_data("order_id", @order.id)
      invoice.add_custom_data("user_id", @user.id)
      invoice.add_custom_data("payment_id", @payment.id)

      # Créer la facture PSR
      if invoice.create(customer_phone_or_email)
        Rails.logger.info("[PayDunya] Invoice PSR créée - token: #{invoice.token}")

        # Mettre à jour le paiement
        @payment.update!(
          paydunya_token: invoice.token,
          payment_type: "PSR",
          provider_response: {
            response_code: invoice.response_code,
            response_text: invoice.response_text,
            created_at: Time.current
          }
        )

        Result.new(
          success?: true,
          payment: @payment,
          redirect_url: nil,
          token: invoice.token,
          errors: []
        )
      else
        Rails.logger.error("[PayDunya] Échec création invoice PSR - #{invoice.response_text}")
        @errors << "Erreur PayDunya: #{invoice.response_text}"

        Result.new(
          success?: false,
          payment: @payment,
          redirect_url: nil,
          token: nil,
          errors: @errors
        )
      end
    rescue StandardError => e
      Rails.logger.error("[PayDunya] Exception PSR - #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @errors << "Une erreur inattendue s'est produite lors de l'initialisation du paiement"

      Result.new(
        success?: false,
        payment: @payment,
        redirect_url: nil,
        token: nil,
        errors: @errors
      )
    end

    # Charge le client pour un paiement PSR
    def charge_onsite_invoice(confirmation_code)
      Rails.logger.info("[PayDunya] Charge PSR - payment_id: #{@payment.id}, token: #{@payment.paydunya_token}")

      return Result.new(success?: false, payment: @payment, errors: [ "Token PayDunya manquant" ]) unless @payment.paydunya_token

      invoice = Paydunya::Onsite::Invoice.new

      if invoice.charge(@payment.paydunya_token, confirmation_code)
        Rails.logger.info("[PayDunya] Paiement PSR réussi - receipt: #{invoice.receipt_url}")

        # Mettre à jour le paiement
        @payment.update!(
          status: :completed,
          paid_at: Time.current,
          paydunya_invoice_url: invoice.receipt_url,
          provider_response: @payment.provider_response.merge({
            charged_at: Time.current,
            receipt_url: invoice.receipt_url,
            customer: invoice.customer
          })
        )

        # Mettre à jour la commande via AASM
        @order.update_status!("processing", changed_by: nil, note: "Commande passée en traitement après confirmation du paiement")

        Result.new(
          success?: true,
          payment: @payment,
          redirect_url: invoice.receipt_url,
          token: @payment.paydunya_token,
          errors: []
        )
      else
        Rails.logger.error("[PayDunya] Échec charge PSR - #{invoice.response_text}")
        @errors << "Code de confirmation invalide ou expiré"

        Result.new(
          success?: false,
          payment: @payment,
          redirect_url: nil,
          token: nil,
          errors: @errors
        )
      end
    rescue StandardError => e
      Rails.logger.error("[PayDunya] Exception charge PSR - #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @errors << "Une erreur s'est produite lors de la confirmation du paiement"

      Result.new(
        success?: false,
        payment: @payment,
        redirect_url: nil,
        token: nil,
        errors: @errors
      )
    end

    # Vérifie le statut d'un paiement
    def check_payment_status
      Rails.logger.info("[PayDunya] Vérification statut - payment_id: #{@payment.id}, token: #{@payment.paydunya_token}")

      return Result.new(success?: false, payment: @payment, errors: [ "Token PayDunya manquant" ]) unless @payment.paydunya_token

      invoice = if @payment.payment_type == "PSR"
        Paydunya::Onsite::Invoice.new
      else
        Paydunya::Checkout::Invoice.new
      end

      if invoice.confirm(@payment.paydunya_token)
        Rails.logger.info("[PayDunya] Statut vérifié - status: #{invoice.status}")

        # Mettre à jour selon le statut
        case invoice.status.downcase
        when "completed", "success"
          @payment.update!(
            status: :completed,
            paid_at: Time.current,
            provider_response: @payment.provider_response.merge({
              confirmed_at: Time.current,
              status: invoice.status
            })
          )
          @order.update_status!("processing", changed_by: nil, note: "Paiement confirmé")
        when "cancelled", "canceled"
          @payment.update!(status: :failed)
          @order.update_status!("canceled", changed_by: nil, note: "Commande annulée suite à l'annulation du paiement")
        end

        Result.new(
          success?: true,
          payment: @payment,
          redirect_url: invoice.receipt_url,
          token: @payment.paydunya_token,
          errors: []
        )
      else
        Rails.logger.warn("[PayDunya] Token invalide - #{invoice.response_text}")
        @errors << "Impossible de vérifier le statut du paiement"

        Result.new(
          success?: false,
          payment: @payment,
          redirect_url: nil,
          token: nil,
          errors: @errors
        )
      end
    rescue StandardError => e
      Rails.logger.error("[PayDunya] Exception vérification - #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      @errors << "Une erreur s'est produite lors de la vérification du paiement"

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
