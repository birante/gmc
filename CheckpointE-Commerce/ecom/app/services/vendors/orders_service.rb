# frozen_string_literal: true

module Vendors
  # Service pour orchestrer les opérations sur les commandes d'un vendor
  #
  # Usage:
  #   service = Vendors::OrdersService.new(vendor: vendor, shop_condition: condition, shop_value: value)
  #   result = service.index(filters: params)
  class OrdersService
    def initialize(vendor:, shop_condition:, shop_value:)
      @vendor = vendor
      @shop_condition = shop_condition
      @shop_value = shop_value
      @query = VendorOrdersQuery.new(vendor: vendor, shop_condition: shop_condition, shop_value: shop_value)
    end

    def index(filters: {})
      @query.set_filters(filters)
      {
        orders: @query.call(filters: filters),
        total_orders: @query.total_count,
        pending_orders: @query.pending_count,
        total_revenue: @query.total_revenue,
        recent_orders_count: @query.recent_count
      }
    end

    def find_order(order_id)
      @query.find_with_order_items(order_id)
    end

    private

    attr_reader :vendor, :shop_condition, :shop_value, :query
  end
end
