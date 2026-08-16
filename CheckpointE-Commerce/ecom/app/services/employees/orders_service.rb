# frozen_string_literal: true

module Employees
  # Service pour orchestrer les opérations sur les commandes accessibles à un collaborateur.
  #
  # Calqué sur Vendors::OrdersService, mais la portée est limitée aux boutiques
  # assignées au collaborateur (via shop_condition / shop_value) et les commandes
  # 'pending' restent visibles (le collaborateur doit pouvoir les traiter).
  #
  # Usage:
  #   service = Employees::OrdersService.new(employee: employee, shop_condition: condition, shop_value: value)
  #   result = service.index(filters: params)
  class OrdersService
    def initialize(employee:, shop_condition:, shop_value:)
      @employee = employee
      @shop_condition = shop_condition
      @shop_value = shop_value
      @query = EmployeeOrdersQuery.new(employee: employee, shop_condition: shop_condition, shop_value: shop_value)
    end

    def index(filters: {})
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

    attr_reader :employee, :shop_condition, :shop_value, :query
  end
end
