module Vendors
  class PaydunyaCallbacksController < ApplicationController
    include VendorsHelper

    skip_before_action :verify_authenticity_token, only: [ :ipn ]
    allow_unauthenticated_access only: [ :ipn, :subscription_success, :subscription_cancel ]
    before_action :set_subscription_payment, only: [ :subscription_success ]

    # Callback apres succes de paiement d'abonnement
    def subscription_success
      Rails.logger.info("[PayDunya Callback] Subscription Success - token: #{params[:token]}")

      if @subscription_payment
        @shop = @subscription_payment.shop
        @vendor = @shop.vendor

        # Verifier le statut du paiement aupres de PayDunya (utiliser le service HTTP)
        service = PaymentServices::SubscriptionPaydunyaHttpService.new(
          subscription_payment: @subscription_payment,
          shop: @shop,
          plan: @subscription_payment.plan
        )

        result = service.check_payment_status
        @subscription_payment.reload

        if result.success? && @subscription_payment.completed?
          # Verifier si c'est un upgrade
          is_upgrade = @subscription_payment.payment_type == "UPGRADE"

          # Verifier si la subscription existe deja (pour eviter les doublons)
          unless Subscription.exists?(shop: @shop, plan: @subscription_payment.plan, status: "active")
            # Si c'est un upgrade, annuler l'ancienne subscription d'abord
            if is_upgrade && @shop.current_subscription
              old_subscription = @shop.current_subscription
              old_plan_name = old_subscription.plan.name
              old_subscription.update!(status: "cancelled")
              Rails.logger.info("[Vendors::PaydunyaCallbacks] Ancienne subscription annulee - subscription_id: #{old_subscription.id}, plan: #{old_plan_name}")
            end

            subscription = Subscription.create!(
              shop: @shop,
              plan: @subscription_payment.plan,
              status: "active",
              started_at: Time.current,
              ends_at: 1.year.from_now
            )
            Rails.logger.info("[Vendors::PaydunyaCallbacks] Subscription creee - subscription_id: #{subscription.id}, shop_id: #{@shop.id}, is_upgrade: #{is_upgrade}")
          else
            Rails.logger.info("[Vendors::PaydunyaCallbacks] Subscription deja existante - shop_id: #{@shop.id}")
          end

          # Verifier si le vendor est connecte, sinon le reconnecter
          if current_vendor.nil? || current_vendor.id != @vendor.id
            Rails.logger.info("[Vendors::PaydunyaCallbacks] Reconnexion du vendor - vendor_id: #{@vendor.id}")
            # Creer une session pour le vendor
            start_new_session_for(@vendor)
            session[:vendor_id] = @vendor.id
          end

          # Rediriger vers le dashboard avec le shop
          notice_message = if is_upgrade
            "Mise a niveau reussie! Votre abonnement #{@subscription_payment.plan.name} est maintenant actif."
          else
            "Paiement confirme! Votre abonnement #{@subscription_payment.plan.name} est maintenant actif."
          end
          redirect_to url_with_shop(vendors_dashboard_path, @shop), notice: notice_message
        else
          Rails.logger.warn("[Vendors::PaydunyaCallbacks] Paiement non confirme - status: #{@subscription_payment.status}")

          # Meme si le paiement n'est pas confirme, rediriger vers le dashboard si le vendor est connecte
          if current_vendor
            redirect_to url_with_shop(vendors_dashboard_path, @shop),
                        alert: "Le paiement n'a pas pu etre confirme. Veuillez contacter le support."
          else
            redirect_to new_vendors_session_path,
                        alert: "Le paiement n'a pas pu etre confirme. Veuillez vous reconnecter et contacter le support."
          end
        end
      else
        Rails.logger.error("[Vendors::PaydunyaCallbacks] Paiement introuvable - token: #{params[:token]}")
        redirect_to root_path, alert: "Paiement introuvable"
      end
    end

    # Callback apres annulation de paiement d'abonnement
    def subscription_cancel
      Rails.logger.warn("[PayDunya Callback] Subscription Cancel - token: #{params[:token]}")

      token = params[:token]
      subscription_payment = SubscriptionPayment.find_by(paydunya_token: token)
      @shop = subscription_payment&.shop

      if subscription_payment
        subscription_payment.update(
          status: "failed",
          failure_reason: "Paiement annule par l'utilisateur"
        )
        Rails.logger.info("[Vendors::PaydunyaCallbacks] Paiement annule - payment_id: #{subscription_payment.id}")

        # Rediriger vers la page de selection de plan pour reessayer
        if current_vendor && @shop
          redirect_to new_vendors_plan_path(plan_id: subscription_payment.plan_id),
                      alert: "Paiement annule. Vous pouvez reessayer."
        else
          redirect_to new_vendors_session_path,
                      alert: "Paiement annule. Veuillez vous reconnecter pour reessayer."
        end
      else
        redirect_to new_vendors_session_path,
                    alert: "Paiement annule."
      end
    end

    # Endpoint IPN (Instant Payment Notification) pour les notifications asynchrones
    def ipn
      Rails.logger.info("[PayDunya IPN] Subscription IPN recu")

      token = params[:token]
      return head :ok if token.blank?

      subscription_payment = SubscriptionPayment.find_by(paydunya_token: token)
      return head :ok unless subscription_payment

      service = PaymentServices::SubscriptionPaydunyaHttpService.new(
        subscription_payment: subscription_payment,
        shop: subscription_payment.shop,
        plan: subscription_payment.plan
      )

      result = service.check_payment_status

      if result.success? && subscription_payment.completed?
        shop = subscription_payment.shop
        is_upgrade = subscription_payment.payment_type == "UPGRADE"

        # Verifier si la subscription existe deja
        unless Subscription.exists?(shop: shop, plan: subscription_payment.plan, status: "active")
          # Si c'est un upgrade, annuler l'ancienne subscription
          if is_upgrade && shop.current_subscription
            shop.current_subscription.update!(status: "cancelled")
            Rails.logger.info("[Vendors::PaydunyaCallbacks IPN] Ancienne subscription annulee - shop_id: #{shop.id}")
          end

          Subscription.create!(
            shop: shop,
            plan: subscription_payment.plan,
            status: "active",
            started_at: Time.current,
            ends_at: 1.year.from_now
          )

          Rails.logger.info("[Vendors::PaydunyaCallbacks] Subscription creee via IPN - shop_id: #{shop.id}, is_upgrade: #{is_upgrade}")
        end
      end

      head :ok
    end

    private

    def set_subscription_payment
      @subscription_payment = SubscriptionPayment.find_by(paydunya_token: params[:token])
    end
  end
end
