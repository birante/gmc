# frozen_string_literal: true

module Notifications
  module OrderNotifications
    # Notification de confirmation de commande au client
    class OrderConfirmationNotification < BaseNotification
      def initialize(order:, **options)
        super(recipient: order.user, **options)
        @order = order
      end

      protected

      def sms_message
        "Votre commande ##{@order.id} a été créée avec succès. Montant: #{@order.final_amount} #{currency_symbol}. Merci pour votre confiance!"
      end

      def sms_type
        "notification"
      end

      def whatsapp_message
        "Votre commande ##{@order.id} a été créée avec succès. Montant: #{@order.final_amount} #{currency_symbol}. Merci pour votre confiance!"
      end

      def mailer_class
        # TODO: Créer OrderConfirmationMailer si nécessaire
        nil
      end

      def mailer_method
        nil
      end

      def mailer_params
        { order: @order }
      end

      private

      def currency_symbol
        @order.currency&.symbol || @order.currency&.code || "XOF"
      end
    end
  end
end
