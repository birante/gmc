# frozen_string_literal: true

module Notifications
  module OrderNotifications
    # Notification de nouvelle commande au vendeur
    class VendorNewOrderNotification < BaseNotification
      def initialize(vendor:, order:, shop:, **options)
        super(recipient: vendor, **options)
        @order = order
        @shop = shop
      end

      protected

      def sms_message
        build_message
      end

      def sms_type
        "notification"
      end

      def whatsapp_message
        build_message
      end

      def mailer_class
        Vendors::OrderNotificationMailer
      end

      def mailer_method
        :new_order
      end

      def mailer_params
        { vendor: @recipient, order: @order, shop: @shop }
      end

      private

      def build_message
        shop_items = @order.order_items.where(shop: @shop)
        shop_total = shop_items.sum(&:total_price)
        currency = @order.currency&.symbol || @order.currency&.code || "XOF"
        "Nouvelle commande ##{@order.order_number} pour #{@shop.name}. Montant: #{shop_total} #{currency}. #{shop_items.count} article(s)."
      end
    end
  end
end
