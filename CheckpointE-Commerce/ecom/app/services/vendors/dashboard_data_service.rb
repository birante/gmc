# frozen_string_literal: true

module Vendors
  # Service pour orchestrer le chargement des données du dashboard vendor
  #
  # Usage:
  #   service = Vendors::DashboardDataService.new(vendor: vendor, shop_condition: condition, shop_value: value)
  #   data = service.call
  class DashboardDataService
    def initialize(vendor:, shop_condition:, shop_value:, current_shop: nil)
      @vendor = vendor
      @shop_condition = shop_condition
      @shop_value = shop_value
      @current_shop = current_shop
      @orders_query = VendorOrdersQuery.new(vendor: vendor, shop_condition: shop_condition, shop_value: shop_value)
      @dashboard_query = VendorDashboardQuery.new(shop_condition: shop_condition, shop_value: shop_value)
      @shop_repository = ShopRepository.new
      @item_repository = ItemRepository.new
    end

    def call
      shops = load_shops
      {
        shops: shops,
        shops_stats: calculate_shops_stats(shops),
        orders_stats: calculate_orders_stats,
        revenue_stats: calculate_revenue_stats,
        items_stats: calculate_items_stats,
        stats: calculate_dashboard_stats,
        top_articles: calculate_top_articles,
        weekly_data: calculate_weekly_data,
        financial_stats: calculate_financial_stats,
        employees_stats: calculate_employees_stats,
        top_clients: calculate_top_clients,
        recent_orders: load_recent_orders,
        recent_items: load_recent_items
      }
    end

    private

    attr_reader :vendor, :shop_condition, :shop_value, :current_shop, :orders_query, :dashboard_query, :shop_repository, :item_repository

    def load_shops
      @shop_repository.for_vendor(vendor)
    end

    def calculate_shops_stats(shops)
      {
        total: shops.count,
        active: shops.active.count,
        pending: shops.pending.count
      }
    end

    def load_shops_stats
      shops = load_shops
      calculate_shops_stats(shops)
    end

    def calculate_orders_stats
      {
        total: @orders_query.total_count,
        pending: @orders_query.pending_count
      }
    end

    def calculate_revenue_stats
      last_month_start = 2.months.ago.beginning_of_month
      last_month_end = 1.month.ago.beginning_of_month
      current_month_start = 1.month.ago.beginning_of_month

      last_month_revenue = @dashboard_query.revenue_by_period(last_month_start, last_month_end)
      current_month_revenue = @dashboard_query.revenue_since(current_month_start)

      {
        total: @orders_query.total_revenue,
        last_month: last_month_revenue,
        current_month: current_month_revenue,
        change: last_month_revenue > 0 ? (((current_month_revenue - last_month_revenue) / last_month_revenue) * 100).round(1) : (current_month_revenue > 0 ? 100 : 0)
      }
    end

    def calculate_items_stats
      total_items = if @current_shop
        @item_repository.count_for_shop(@current_shop)
      else
        @shop_repository.count_items_for_vendor(vendor)
      end
      { total: total_items }
    end

    def calculate_dashboard_stats
      last_month_start = 2.months.ago.beginning_of_month
      last_month_end = 1.month.ago.beginning_of_month
      current_month_start = 1.month.ago.beginning_of_month
      current_week_start = 6.days.ago.beginning_of_day
      previous_week_start = 13.days.ago.beginning_of_day

      previous_month_orders = @dashboard_query.orders_count_by_period(last_month_start, last_month_end)
      previous_month_carts = @dashboard_query.carts_abandoned_by_period(last_month_start, last_month_end)

      total_orders = @orders_query.total_count
      total_items = calculate_items_stats[:total]
      pending_orders = @orders_query.pending_count
      current_week_units_sold = @dashboard_query.weekly_sales_by_days(current_week_start, days: 7).sum
      previous_week_units_sold = @dashboard_query.weekly_sales_by_days(previous_week_start, days: 7).sum

      current_carts_abandoned = @dashboard_query.carts_abandoned_since(current_month_start)

      {
        total_views: total_orders,
        views_change: previous_month_orders > 0 ? (((total_orders - previous_month_orders).to_f / previous_month_orders) * 100).round(1) : (total_orders > 0 ? 100 : 0),
        total_sessions: current_week_units_sold,
        sessions_change: previous_week_units_sold > 0 ? (((current_week_units_sold - previous_week_units_sold).to_f / previous_week_units_sold) * 100).round(1) : (current_week_units_sold > 0 ? 100 : 0),
        catalog_items_count: total_items,
        monthly_traffic: @dashboard_query.orders_count_since(current_month_start),
        cart_abandoned: current_carts_abandoned,
        cart_change: previous_month_carts > 0 ? (((current_carts_abandoned - previous_month_carts).to_f / previous_month_carts) * 100).round(1) : 0,
        cart_pending: pending_orders,
        cart_pending_percent: total_orders > 0 ? ((pending_orders.to_f / total_orders) * 100).round : 0,
        new_clients: @dashboard_query.new_clients_since(current_month_start),
        sales_volume: calculate_revenue_stats[:current_month],
        sales_change: calculate_revenue_stats[:change]
      }
    end

    def calculate_top_articles
      top_items_data = @dashboard_query.top_items_by_sales(limit: 3)

      colors = [ "#551694", "#7c1fc4", "#9d4edd" ]
      top_articles = top_items_data.map.with_index do |(item_name, quantity), index|
        {
          name: item_name || "Article inconnu",
          value: quantity.to_i,
          color: colors[index % colors.length]
        }
      end

      # Compléter avec des placeholders si nécessaire
      (3 - top_articles.count).times do |i|
        top_articles << { name: "Aucun article", value: 0, color: colors[top_articles.count + i] }
      end

      top_articles
    end

    def calculate_weekly_data
      start_date = 6.days.ago.beginning_of_day
      daily_sales = @dashboard_query.weekly_sales_by_days(start_date, days: 7)

      {
        labels: [ "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim" ],
        values: daily_sales
      }
    end

    def calculate_financial_stats
      if @current_shop
        {
          balance: @current_shop.balance || 0,
          pending_payout: @current_shop.pending_payout_amount || 0
        }
      else
        # Optimisation: utiliser SQL sum au lieu de charger tous les shops en mémoire
        balance = vendor.shops.sum(:balance) || 0
        pending_payout = vendor.shops.sum(:pending_payout_amount) || 0
        {
          balance: balance,
          pending_payout: pending_payout
        }
      end
    end

    def calculate_employees_stats
      {
        total: vendor.employees.count,
        active: vendor.employees.active.count,
        recent: vendor.employees.includes(shops: [], employee_shops: :shop).order(created_at: :desc).limit(5)
      }
    end

    def calculate_top_clients
      recent_clients = @dashboard_query.recent_clients(limit: 6, since: 1.month.ago)

      colors_client = [ "bg-[#551694]", "bg-[#7c1fc4]", "bg-[#9d4edd]", "bg-[#c77dff]", "bg-[#e0aaff]", "bg-[#f3d9ff]" ]
      recent_clients.map.with_index do |(first_name, last_name), index|
        {
          initial: (first_name || last_name || "C")[0].upcase,
          color: colors_client[index % colors_client.length]
        }
      end
    end

    def load_recent_orders
      shop_ids = @current_shop ? [ @current_shop.id ] : vendor.shops.pluck(:id)
      @dashboard_query.recent_orders(shop_ids: shop_ids, limit: 10)
    end

    def load_recent_items
      @dashboard_query.recent_items(limit: 8)
    end
  end
end
