# frozen_string_literal: true

module Notifications
  # Service centralisé pour envoyer toutes les notifications
  #
  # Ce service unifie l'envoi de notifications multi-canaux (SMS, Email, WhatsApp)
  # pour tous les événements de l'application (commandes, paiements, vérifications).
  #
  # Usage:
  #   # Confirmation de commande
  #   Notifications::NotificationService.send_order_confirmation(
  #     order,
  #     send_sms: true,
  #     send_email: true
  #   )
  #
  #   # Nouvelle commande pour vendeur
  #   Notifications::NotificationService.send_vendor_new_order(
  #     vendor: vendor,
  #     order: order,
  #     shop: shop,
  #     send_email: true
  #   )
  #
  #   # Code de vérification
  #   Notifications::NotificationService.send_verification_code(
  #     recipient: user,
  #     code: "1234",
  #     channel: "sms"
  #   )
  #
  # @see Notifications::BaseNotification
  class NotificationService
    # Envoie une notification de confirmation de commande
    def self.send_order_confirmation(order, send_sms: true, send_whatsapp: false, send_email: false)
      notification = OrderNotifications::OrderConfirmationNotification.new(
        order: order,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end

    # Envoie une notification de nouvelle commande au vendeur
    def self.send_vendor_new_order(vendor:, order:, shop:, send_sms: false, send_whatsapp: false, send_email: true)
      notification = OrderNotifications::VendorNewOrderNotification.new(
        vendor: vendor,
        order: order,
        shop: shop,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end

    # Envoie une notification de changement de statut de commande
    def self.send_order_status_change(order:, status:, send_sms: false, send_whatsapp: false, send_email: true)
      notification = OrderNotifications::OrderStatusChangeNotification.new(
        order: order,
        status: status,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end

    # Envoie une notification de livraison d'article
    def self.send_order_item_delivered(order_item:, send_sms: false, send_whatsapp: false, send_email: false)
      notification = OrderNotifications::OrderItemDeliveredNotification.new(
        order_item: order_item,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end

    # Envoie une notification de changement de statut d'article de commande
    def self.send_order_item_status_change(order_item:, old_status: nil, send_sms: false, send_whatsapp: false, send_email: true)
      notification = OrderNotifications::OrderItemStatusChangeNotification.new(
        order_item: order_item,
        old_status: old_status,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end

    # Envoie une notification de code de vérification
    def self.send_verification_code(recipient:, code:, channel: "sms", send_sms: true, send_whatsapp: false, send_email: true)
      notification = Notifications::VerificationCodeNotification.new(
        recipient: recipient,
        code: code,
        channel: channel,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end

    # Envoie une notification de réinitialisation de mot de passe
    def self.send_password_reset(recipient:, reset_token:, reset_url:, send_sms: true, send_whatsapp: false, send_email: true)
      notification = Notifications::PasswordResetNotification.new(
        recipient: recipient,
        reset_token: reset_token,
        reset_url: reset_url,
        send_sms: send_sms,
        send_whatsapp: send_whatsapp,
        send_email: send_email
      )
      notification.deliver
    end
  end
end
