# frozen_string_literal: true

module Vendors
  class OrderNotificationMailer < ApplicationMailer
    # Envoie une notification au vendeur lorsqu'une nouvelle commande est créée
    # @param vendor [Vendor] Le vendeur à notifier
    # @param order [Order] La commande créée
    # @param shop [Shop] La boutique concernée par la commande
    def new_order(vendor:, order:, shop:)
      @vendor = vendor
      @order = order
      @shop = shop
      # Précharger order_items avec les associations nécessaires
      @order_items = order.order_items.includes(:item, :item_variant, :shop).where(shop: shop)
      @client = order.user

      Rails.logger.info("📧 [Vendors::OrderNotificationMailer] Envoi notification nouvelle commande - vendor_id: #{vendor.id}, order_id: #{order.id}, shop_id: #{shop.id}")

      mail(
        to: vendor.email,
        subject: "Nouvelle commande ##{order.order_number} - #{shop.name}"
      )
    end
  end
end
