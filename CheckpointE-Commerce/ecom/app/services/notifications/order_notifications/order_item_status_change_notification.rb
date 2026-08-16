# frozen_string_literal: true

module Notifications
  module OrderNotifications
    # Notification de changement de statut d'article de commande au client
    class OrderItemStatusChangeNotification < BaseNotification
      def initialize(order_item:, old_status: nil, **options)
        super(recipient: order_item.order.user, **options)
        @order_item = order_item
        @order = order_item.order
        @old_status = old_status
        @new_status = order_item.delivery_status
      end

      protected

      def sms_message
        # SMS désactivé pour l'instant
        nil
      end

      def sms_type
        "notification"
      end

      def mailer_class
        # Utiliser le mailer de statut de commande si disponible
        # Sinon, créer un mailer spécifique pour les items si nécessaire
        Client::OrderStatusMailer
      end

      def mailer_method
        # Mapper le statut de l'item vers une méthode mailer appropriée
        case @new_status
        when "pending_shipment"
          # Pas besoin de notifier pour pending_shipment (statut initial)
          nil
        when "shipped"
          :item_shipped
        when "delivered"
          :item_delivered
        when "failed"
          :item_failed
        when "returned"
          :item_returned
        else
          nil
        end
      end

      def mailer_params
        { order_item: @order_item, order: @order }
      end

      # Override pour ne pas envoyer si pas de méthode mailer
      def deliver_email
        return nil unless should_send_email?
        return nil unless recipient_email.present?
        return nil unless mailer_method.present? # Ne pas envoyer si pas de méthode mailer

        begin
          mailer_class.with(mailer_params).public_send(mailer_method).deliver_later
          Rails.logger.info("✅ [OrderItemStatusChangeNotification] Email envoyé - order_item_id: #{@order_item.id}, statut: #{@new_status}, recipient: #{recipient_email}")
          { success: true, message: "Email envoyé avec succès" }
        rescue StandardError => e
          Rails.logger.error("❌ [OrderItemStatusChangeNotification] Erreur envoi email - order_item_id: #{@order_item.id}, erreur: #{e.message}")
          { success: false, error: e.message }
        end
      end
    end
  end
end
