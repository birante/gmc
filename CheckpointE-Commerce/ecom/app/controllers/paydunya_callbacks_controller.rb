class PaydunyaCallbacksController < ApplicationController
  helper VendorsHelper, EmployeesHelper
  skip_before_action :verify_authenticity_token, only: [ :ipn ]
  allow_unauthenticated_access only: [ :ipn ]
  before_action :set_payment, only: [ :success, :charge ]
  before_action :set_subscription_payment, only: [ :subscription_success, :subscription_cancel ]

  # Callback après succès de paiement (PAR)
  def success
    Rails.logger.info("[PayDunya Callback] Success - token: #{params[:token]}")

    # Si le token correspond à un paiement d'abonnement, déléguer au callback abonnement
    subscription_payment = SubscriptionPayment.find_by(paydunya_token: params[:token]) if params[:token].present?
    if subscription_payment
      Rails.logger.info("[PayDunya Callback] Token abonnement détecté, redirection vers subscription_success")
      redirect_to url_for(controller: "vendors/paydunya_callbacks", action: "subscription_success", token: params[:token], locale: I18n.locale, only_path: false) and return
    end

    if @payment
      # Vérifier le statut du paiement auprès de PayDunya
      service = PaymentServices::PaydunyaService.new(
        payment: @payment,
        order: @payment.order,
        user: @payment.order.user
      )

      result = service.check_payment_status

      if result.success? && @payment.completed?
        # TODO: Envoyer SMS de confirmation de paiement
        # Le SMS sera envoyé automatiquement par le callback after_update de Payment
        # Mais on peut aussi envoyer un SMS ici pour confirmer immédiatement:
        # if @payment.order.user.phone_number.present?
        #   message = "Votre paiement de #{@payment.amount} #{@payment.order.currency&.symbol || @payment.order.currency&.code} a été confirmé. Commande ##{@payment.order.id} en cours de traitement."
        #   Sms::SmsService.new.send_sms(
        #     to: @payment.order.user.formatted_phone_number,
        #     message: message,
        #     sms_type: "notification"
        #   )
        # rescue Sms::SmsService::SmsDisabledError => e
        #   Rails.logger.info("SMS désactivé, notification non envoyée")
        # rescue StandardError => e
        #   Rails.logger.error("Erreur envoi SMS confirmation paiement: #{e.message}")
        # end
        redirect_to client_orders_path, notice: "✅ Paiement confirmé! Votre commande est en cours de traitement."
      else
        redirect_to client_orders_path, alert: "⚠️ Le paiement n'a pas pu être confirmé. Veuillez contacter le support."
      end
    else
      redirect_to root_path, alert: "Paiement introuvable"
    end
  end

  # Callback après annulation de paiement (PAR)
  def cancel
    Rails.logger.warn("[PayDunya Callback] Cancel - token: #{params[:token]}")

    token = params[:token]
    if token.present?
      payment = Payment.find_by(paydunya_token: token)
      if payment
        payment.update(status: :failed)
        if payment.order.update_status!("canceled", changed_by: nil, note: "Commande annulée suite à l'annulation du paiement")
          redirect_to client_orders_path, alert: "❌ Le paiement a été annulé. Votre commande a été annulée."
        else
          redirect_to client_orders_path, alert: "❌ Le paiement a été annulé mais la commande n'a pas pu être annulée."
        end
      else
        redirect_to root_path, alert: "Paiement introuvable"
      end
    else
      redirect_to root_path, alert: "Token manquant"
    end
  end

  # IPN (Instant Payment Notification) - Webhook PayDunya
  def ipn
    Rails.logger.info("[PayDunya IPN] Notification reçue - params: #{params.inspect}")

    # Récupérer les données de l'IPN
    token = params[:data][:token] rescue nil

    if token.present?
      payment = Payment.find_by(paydunya_token: token)

      if payment
        # Vérifier le statut du paiement
        service = PaymentServices::PaydunyaService.new(
          payment: payment,
          order: payment.order,
          user: payment.order.user
        )

        result = service.check_payment_status

        if result.success?
          Rails.logger.info("[PayDunya IPN] Paiement vérifié - payment_id: #{payment.id}")
          render json: { status: "success" }, status: :ok
        else
          Rails.logger.error("[PayDunya IPN] Échec vérification - payment_id: #{payment.id}")
          render json: { status: "error", errors: result.errors }, status: :unprocessable_entity
        end
      else
        Rails.logger.warn("[PayDunya IPN] Paiement introuvable - token: #{token}")
        render json: { status: "error", message: "Payment not found" }, status: :not_found
      end
    else
      Rails.logger.error("[PayDunya IPN] Token manquant")
      render json: { status: "error", message: "Token missing" }, status: :bad_request
    end
  end

  # Charge un paiement PSR avec le code de confirmation
  def charge
    Rails.logger.info("[PayDunya Charge] Tentative charge PSR - payment_id: #{@payment&.id}")

    confirmation_code = params[:confirmation_code]

    if @payment.nil?
      render json: { success: false, error: "Paiement introuvable" }, status: :not_found
      return
    end

    if confirmation_code.blank?
      render json: { success: false, error: "Code de confirmation requis" }, status: :unprocessable_entity
      return
    end

    service = PaymentServices::PaydunyaService.new(
      payment: @payment,
      order: @payment.order,
      user: @payment.order.user
    )

    result = service.charge_onsite_invoice(confirmation_code)

    if result.success?
      render json: {
        success: true,
        message: "Paiement confirmé avec succès",
        receipt_url: result.redirect_url,
        order_url: client_order_url(@payment.order)
      }, status: :ok
    else
      render json: {
        success: false,
        error: result.errors.join(", ")
      }, status: :unprocessable_entity
    end
  end

  # Callback après succès de paiement de subscription
  def subscription_success
    Rails.logger.info("[PayDunya Subscription Callback] Success - token: #{params[:token]}")

    unless @subscription_payment
      Rails.logger.warn("[PayDunya Subscription Callback] Paiement introuvable - token: #{params[:token]}")
      redirect_to root_path, alert: "Paiement introuvable"
      return
    end

    # Vérifier le statut du paiement auprès de PayDunya
    service = PaymentServices::SubscriptionPaydunyaService.new(
      subscription_payment: @subscription_payment,
      shop: @subscription_payment.shop,
      plan: @subscription_payment.plan
    )

    # Vérifier que le paiement a bien été effectué (VRAIE validation comme pour les commandes)
    result = service.check_payment_status

    if result.success? && @subscription_payment.completed?
      # Créer la subscription active
      subscription = Subscription.create!(
        shop: @subscription_payment.shop,
        plan: @subscription_payment.plan,
        status: "active",
        started_at: Time.current,
        ends_at: 1.year.from_now
      )

      Rails.logger.info("✅ [PayDunya Subscription Callback] Subscription créée - subscription_id: #{subscription.id}, shop_id: #{@subscription_payment.shop.id}, plan: #{@subscription_payment.plan.code}")

      # Rediriger vers le dashboard de la boutique
      shop = @subscription_payment.shop
      redirect_to url_with_shop(vendors_dashboard_path, shop),
                  notice: "✅ Paiement confirmé! Votre abonnement est maintenant actif."
    else
      Rails.logger.error("[PayDunya Subscription Callback] Échec vérification paiement - payment_id: #{@subscription_payment.id}, errors: #{result.errors.inspect}")
      @subscription_payment.update(status: "failed", failure_reason: result.errors.join(", "))
      redirect_to new_vendors_plan_path(tab: "independants"),
                  alert: "⚠️ Le paiement n'a pas pu être confirmé. Veuillez contacter le support."
    end
  end

  # Callback après annulation de paiement de subscription
  def subscription_cancel
    Rails.logger.warn("[PayDunya Subscription Callback] Cancel - token: #{params[:token]}")

    unless @subscription_payment
      Rails.logger.warn("[PayDunya Subscription Callback Cancel] Paiement introuvable - token: #{params[:token]}")
      redirect_to root_path, alert: "Paiement introuvable"
      return
    end

    # Marquer le paiement comme échoué
    @subscription_payment.update(
      status: "failed",
      failure_reason: "Paiement annulé par l'utilisateur"
    )

    Rails.logger.warn("⚠️ [PayDunya Subscription Callback] Paiement annulé - payment_id: #{@subscription_payment.id}")

    # Rediriger vers le formulaire de sélection du plan
    redirect_to new_vendors_plan_path(tab: "independants"),
                alert: "❌ Le paiement a été annulé. Veuillez réessayer si vous souhaitez continuer."
  end

  private

  def set_subscription_payment
    token = params[:token]
    @subscription_payment = SubscriptionPayment.find_by(paydunya_token: token) if token.present?
  end

  def set_payment
    token = params[:token]
    @payment = Payment.find_by(paydunya_token: token) if token.present?
  end
end
