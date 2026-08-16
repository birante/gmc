# frozen_string_literal: true

module Vendors
  # Service pour vérifier l'accès aux commandes
  #
  # Usage:
  #   service = Vendors::OrderAccessService.new(vendor: vendor, shop_condition: condition, shop_value: value)
  #   result = service.check_access(order_id)
  class OrderAccessService
    def initialize(vendor:, shop_condition:, shop_value:)
      @vendor = vendor
      @shop_condition = shop_condition
      @shop_value = shop_value
    end

    def check_access(order_id)
      begin
        order = Order.friendly.find(order_id)
      rescue ActiveRecord::RecordNotFound
        return { accessible: false, order: nil, error: :not_found }
      end

      # Vérifier que cette commande appartient bien au vendor
      accessible_items = order.order_items.joins(:shop)
                            .where(@shop_condition, @shop_value)

      if accessible_items.empty?
        return { accessible: false, order: nil, error: :unauthorized }
      end

      { accessible: true, order: order, error: nil }
    end

    def check_order_item_access(order_item_id)
      order_item = OrderItem.joins(:shop)
                           .where(id: order_item_id)
                           .where(@shop_condition, @shop_value)
                           .first

      { accessible: order_item.present?, order_item: order_item }
    end

    private

    attr_reader :vendor, :shop_condition, :shop_value
  end
end
