# frozen_string_literal: true

module Employees
  # Service pour orchestrer le chargement des données du dashboard employee
  #
  # Usage:
  #   service = Employees::DashboardDataService.new(employee: employee, current_shop: shop)
  #   data = service.call
  class DashboardDataService
    def initialize(employee:, current_shop:)
      @employee = employee
      @current_shop = current_shop
      @vendor = employee.vendor
      @shop_ids = @current_shop ? [ @current_shop.id ] : employee.shops.pluck(:id)
      @orders_query = EmployeeOrdersQuery.new(employee: employee, shop_condition: "shops.id IN (?)", shop_value: @shop_ids)
      @shop_condition = "order_items.shop_id = ?"
      @shop_value = @current_shop&.id
      @dashboard_query = EmployeeDashboardQuery.new(shop_condition: @shop_condition, shop_value: @shop_value)
      @shop_repository = ShopRepository.new
      @item_repository = ItemRepository.new
    end

    def call
      return empty_data unless @current_shop

      {
        shops: load_shops,
        total_items: calculate_total_items,
        orders_stats: calculate_orders_stats,
        revenue_stats: calculate_revenue_stats,
        stats: calculate_dashboard_stats,
        top_articles: calculate_top_articles,
        weekly_data: calculate_weekly_data,
        top_clients: calculate_top_clients,
        recent_orders_by_category: load_recent_orders_by_category,
        # Parité avec Vendors::DashboardDataService (les sections « Mes produits récents »,
        # « Dernières commandes », « Mes collaborateurs » et la carte « Solde disponible »
        # du dashboard partagé)
        recent_items: load_recent_items,
        recent_orders: load_recent_orders_flat,
        employees_stats: calculate_employees_stats,
        financial_stats: calculate_financial_stats
      }
    end

    private

    attr_reader :employee, :current_shop, :vendor, :shop_ids, :orders_query, :shop_condition, :shop_value, :dashboard_query, :shop_repository, :item_repository

    def empty_data
      {
        shops: [],
        total_items: 0,
        orders_stats: { total: 0, pending: 0 },
        revenue_stats: { total: 0, last_month: 0, current_month: 0, change: 0 },
        stats: {},
        top_articles: [],
        weekly_data: { labels: [], values: [] },
        top_clients: [],
        recent_orders_by_category: [],
        recent_items: [],
        recent_orders: Order.none,
        employees_stats: { total: 0, active: 0, recent: Employee.none },
        financial_stats: { balance: 0, pending_payout: 0 }
      }
    end

    def load_shops
      @shop_repository.for_employee(employee)
    end

    def calculate_total_items
      return 0 unless @current_shop
      @item_repository.count_for_shop(@current_shop)
    rescue StandardError
      0
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
        change: last_month_revenue > 0 ? (((current_month_revenue - last_month_revenue) / last_month_revenue) * 100).round(1) : 0
      }
    end

    def calculate_dashboard_stats
      total_orders = @orders_query.total_count
      total_items = calculate_total_items
      pending_orders = @orders_query.pending_count
      current_month_revenue = calculate_revenue_stats[:current_month]
      last_month_revenue = calculate_revenue_stats[:last_month]
      current_month_start = 1.month.ago.beginning_of_month

      {
        total_views: total_orders,
        views_change: 0,
        total_sessions: total_items,
        sessions_change: 0,
        monthly_traffic: @dashboard_query.orders_count_since(current_month_start),
        cart_abandoned: @dashboard_query.carts_abandoned_since(current_month_start),
        cart_change: 0,
        cart_pending: pending_orders,
        cart_pending_percent: total_orders > 0 ? ((pending_orders.to_f / total_orders) * 100).round : 0,
        new_clients: @dashboard_query.new_clients_since(current_month_start),
        sales_volume: current_month_revenue,
        sales_change: last_month_revenue > 0 ? (((current_month_revenue - last_month_revenue) / last_month_revenue) * 100).round(1) : 0,
        # Pour la carte « Articles en catalogue » du dashboard partagé
        catalog_items_count: total_items
      }
    end

    def calculate_top_articles
      top_items_data = @dashboard_query.top_items_by_sales(limit: 3)

      colors = [ "#9CA3AF", "#6B7280", "#4B5563" ]
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

    def calculate_top_clients
      recent_clients = @dashboard_query.recent_clients(limit: 6, since: 1.month.ago)

      colors_client = [ "bg-yellow-400", "bg-green-500", "bg-pink-500", "bg-blue-400", "bg-purple-400", "bg-indigo-400" ]
      top_clients = recent_clients.map.with_index do |(first_name, last_name), index|
        {
          initial: (first_name || "C")[0].upcase,
          color: colors_client[index % colors_client.length]
        }
      end

      # Compléter si nécessaire
      (6 - top_clients.count).times do |i|
        top_clients << { initial: "?", color: colors_client[top_clients.count + i] }
      end

      top_clients
    end

    def load_recent_orders_by_category
      recent_orders_by_category = @dashboard_query.recent_orders_by_category(limit: 3)

      # Compléter si nécessaire
      (3 - recent_orders_by_category.count).times do |i|
        recent_orders_by_category << {
          id: nil,
          name: "Aucune",
          slug: nil,
          order_items: []
        }
      end

      recent_orders_by_category
    end

    # Derniers items pour la section « Mes produits récents » du dashboard partagé.
    # Includes alignés sur VendorDashboardQuery#recent_items pour précharger l'image et la variante par défaut.
    def load_recent_items
      return [] unless @current_shop

      @current_shop.items
                   .includes(:product_sub_category, :currency, :shop, :variants, :main_image_attachment, :images_attachments)
                   .order(created_at: :desc)
                   .limit(8)
    end

    # Dernières commandes (liste plate) pour la section « Dernières commandes »
    def load_recent_orders_flat
      @orders_query.call.limit(10)
    end

    # Statistiques sur les collaborateurs du vendeur (visibles en lecture côté employé pour la parité visuelle)
    def calculate_employees_stats
      employees_scope = @vendor.employees
      {
        total:  employees_scope.count,
        active: employees_scope.active.count,
        recent: employees_scope.includes(:shops).order(created_at: :desc).limit(5)
      }
    end

    # Solde + encours de la boutique active (carte « Solde disponible » du dashboard partagé).
    # Pour un collaborateur, on lit toujours la boutique courante (jamais l'agrégat vendor).
    def calculate_financial_stats
      {
        balance: @current_shop&.balance || 0,
        pending_payout: @current_shop&.pending_payout_amount || 0
      }
    end
  end
end
