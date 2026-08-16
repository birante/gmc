# frozen_string_literal: true

module Notifications
  module OrderNotifications
    # Notification de changement de statut de commande au client
    class OrderStatusChangeNotification < BaseNotification
      def initialize(order:, status:, **options)
        super(recipient: order.user, **options)
        @order = order
        @status = status.to_sym
      end

      protected

      def sms_message
        build_status_message
      end

      def sms_type
        @status == :canceled ? "alert" : "notification"
      end

      def whatsapp_message
        build_status_message
      end

      def mailer_class
        Client::OrderStatusMailer
      end

      def mailer_method
        @status
      end

      def mailer_params
        { order: @order }
      end

      private

      def build_status_message
        case @status
        when :processing
          "Votre commande ##{@order.id} est en cours de traitement. Nous vous tiendrons informé de l'avancement."
        when :shipped
          departure_info = @order.departure_date ? "Le #{@order.departure_date.strftime('%d/%m/%Y à %H:%M')}" : "Aujourd'hui"
          "Votre commande ##{@order.id} a été expédiée! #{departure_info}. Elle arrivera bientôt."
        when :delivered
          "Votre commande ##{@order.id} a été livrée avec succès! Merci d'avoir fait vos achats chez nous."
        when :canceled
          "Votre commande ##{@order.id} a été annulée. Si vous avez des questions, contactez notre service client."
        when :partial_delivery
          "Votre commande ##{@order.id} est partiellement livrée. Certains articles sont déjà arrivés."
        else
          nil
        end
      end
    end
  end
end
