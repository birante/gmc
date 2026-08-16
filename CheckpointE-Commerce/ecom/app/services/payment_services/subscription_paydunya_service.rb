module PaymentServices
  class SubscriptionPaydunyaService
    Result = Struct.new(:success?, :subscription_payment, :redirect_url, :token, :errors, keyword_init: true)

    def initialize(subscription_payment:, shop:, plan:)
      @subscription_payment = subscription_payment
      @shop = shop
      @plan = plan
      @errors = []
    end

    # Crée une invoice pour le paiement de subscription
    def create_checkout_invoice
      Rails.logger.info("[PayDunya Subscription] Création invoice - shop_id: #{@shop.id}, plan: #{@plan.code}, montant: #{@subscription_payment.amount}")

      invoice = Paydunya::Checkout::Invoice.new

      # Ajouter le plan comme article
      invoice.add_item(
        "Abonnement #{@plan.name}",
        1,
        @subscription_payment.amount.to_f,
        @subscription_payment.amount.to_f,
        "Abonnement mensuel - #{@plan.code}"
      )

      # Configurer le montant total
      invoice.total_amount = @subscription_payment.amount.to_f

      # Ajouter une description
      invoice.description = "Abonnement #{@plan.name} - Boutique: #{@shop.name} (#{@shop.code})"

      # Ajouter des données personnalisées
      invoice.add_custom_data("shop_id", @shop.id)
      invoice.add_custom_data("plan_id", @plan.id)
      invoice.add_custom_data("subscription_payment_id", @subscription_payment.id)
      invoice.add_custom_data("payment_type", "subscription")
      invoice.add_custom_data("withdraw_mode", @subscription_payment.withdraw_mode)

      # URLs de callback spécifiques aux abonnements (IMPORTANT: doit être défini AVANT invoice.create)
      urls = PaydunyaConfig.callback_urls(I18n.locale.to_s)
      Paydunya::Checkout::Store.cancel_url = urls[:cancel_url]
      Paydunya::Checkout::Store.return_url = urls[:return_url]

      Rails.logger.info("[PayDunya Subscription] URLs callback - cancel: #{Paydunya::Checkout::Store.cancel_url}, return: #{Paydunya::Checkout::Store.return_url}")

      # Créer la facture
      if invoice.create
        Rails.logger.info("[PayDunya Subscription] Invoice créée - token: #{invoice.token}, url: #{invoice.invoice_url}")

        # Mettre à jour le paiement
        @subscription_payment.update!(
          paydunya_token: invoice.token,
          paydunya_invoice_url: invoice.invoice_url,
          status: "processing",
          provider_response: {
            response_code: invoice.response_code,
            response_text: invoice.response_text,
            created_at: Time.current
          }
        )

        Result.new(
          success?: true,
          subscription_payment: @subscription_payment,
          redirect_url: invoice.invoice_url,
          token: invoice.token,
          errors: []
        )
      else
        Rails.logger.error("[PayDunya Subscription] Échec création invoice - #{invoice.response_text}")
        error_message = case invoice.response_text
        when /Invalid Masterkey/i
          "Configuration PayDunya invalide. Veuillez contacter l'administrateur."
        when /Invalid.*key/i
          "Clés API PayDunya invalides. Veuillez contacter l'administrateur."
        else
          "Erreur PayDunya: #{invoice.response_text}"
        end
        @errors << error_message

        @subscription_payment.update(
          status: "failed",
          failure_reason: error_message
        )

        Result.new(
          success?: false,
          subscription_payment: @subscription_payment,
          redirect_url: nil,
          token: nil,
          errors: @errors
        )
      end
    rescue StandardError => e
      Rails.logger.error("[PayDunya Subscription] Exception - #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      error_message = if e.message =~ /Invalid.*key/i
        "Clés API PayDunya invalides. Veuillez contacter l'administrateur."
      else
        "Erreur PayDunya: #{e.message}"
      end
      @errors << error_message

      @subscription_payment.update(
        status: "failed",
        failure_reason: error_message
      )

      Result.new(
        success?: false,
        subscription_payment: @subscription_payment,
        redirect_url: nil,
        token: nil,
        errors: @errors
      )
    end

    # Vérifie le statut du paiement auprès de PayDunya
    def check_payment_status
      Rails.logger.info("[PayDunya Subscription] Vérification statut - token: #{@subscription_payment.paydunya_token}")

      return Result.new(success?: false, subscription_payment: @subscription_payment, errors: [ "Pas de token PayDunya" ]) unless @subscription_payment.paydunya_token.present?

      invoice = Paydunya::Checkout::Invoice.new

      if invoice.confirm(@subscription_payment.paydunya_token)
        Rails.logger.info("[PayDunya Subscription] Statut vérifié - status: #{invoice.status}")

        # Vérifier si le paiement est complété
        if invoice.status.downcase == "completed" || invoice.status.downcase == "success"
          Rails.logger.info("[PayDunya Subscription] Paiement complété - token: #{@subscription_payment.paydunya_token}")

          @subscription_payment.update!(
            status: "completed",
            paid_at: Time.current,
            provider_response: {
              status: invoice.status,
              verified_at: Time.current,
              response_code: invoice.response_code,
              response_text: invoice.response_text
            }
          )

          Result.new(
            success?: true,
            subscription_payment: @subscription_payment,
            errors: []
          )
        else
          Rails.logger.warn("[PayDunya Subscription] Paiement non complété - token: #{@subscription_payment.paydunya_token}, statut: #{invoice.status}")

          Result.new(
            success?: false,
            subscription_payment: @subscription_payment,
            errors: [ "Paiement non encore confirmé (statut: #{invoice.status})" ]
          )
        end
      else
        Rails.logger.warn("[PayDunya Subscription] Échec confirmation - token invalide ou erreur PayDunya: #{invoice.response_text}")

        Result.new(
          success?: false,
          subscription_payment: @subscription_payment,
          errors: [ "Impossible de vérifier le statut du paiement: #{invoice.response_text}" ]
        )
      end
    rescue StandardError => e
      Rails.logger.error("[PayDunya Subscription] Erreur vérification - #{e.class}: #{e.message}")

      Result.new(
        success?: false,
        subscription_payment: @subscription_payment,
        errors: [ "Erreur lors de la vérification du paiement: #{e.message}" ]
      )
    end
  end
end
