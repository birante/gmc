# frozen_string_literal: true

module Notifications
  module OrderNotifications
    # Notification de livraison d'article au client
    class OrderItemDeliveredNotification < BaseNotification
      def initialize(order_item:, **options)
        super(recipient: order_item.order.user, **options)
        @order_item = order_item
        @order = order_item.order
      end

      protected

      def sms_message
        # Ne pas envoyer si tous les articles sont livrés (le SMS global sera envoyé)
        return nil if @order.order_items.all? { |oi| oi.delivery_status == "delivered" }

        "Un article de votre commande ##{@order.id} (#{@order_item.item.name}) a été livré avec succès."
      end

      def sms_type
        "notification"
      end

      def mailer_class
        # TODO: Créer OrderItemDeliveredMailer si nécessaire
        nil
      end

      def mailer_method
        nil
      end

      def mailer_params
        { order_item: @order_item }
      end
    end
  end
end
