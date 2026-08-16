module Employees
  class DashboardsController < Employees::BaseController
    def show
      @employee = current_employee
      @shops = @employee.shops.order(created_at: :desc)

      # Sélectionner la boutique : celle passée en paramètre, ou la boutique principale, ou la première
      @current_shop = if params[:shop_id].present?
        @shops.find_by(id: params[:shop_id])
      else
        @employee.primary_shop || @shops.first
      end

      @shop = @current_shop
      @vendor = @employee.vendor

      # Utiliser le service pour orchestrer le chargement de toutes les données
      service = Employees::DashboardDataService.new(
        employee: @employee,
        current_shop: @current_shop
      )

      data = service.call

      # Mapper les données du service aux variables d'instance
      @total_items = data[:total_items]
      @total_orders = data[:orders_stats][:total]
      @pending_orders = data[:orders_stats][:pending]
      @total_revenue = data[:revenue_stats][:total]
      @last_month_revenue = data[:revenue_stats][:last_month]
      @current_month_revenue = data[:revenue_stats][:current_month]
      @stats = data[:stats]
      @top_articles = data[:top_articles]
      @weekly_data = data[:weekly_data]
      @top_clients = data[:top_clients]
      @recent_orders_by_category = data[:recent_orders_by_category]

      # Parité avec le dashboard vendor (partial partagé)
      @recent_items     = data[:recent_items]
      @recent_orders    = data[:recent_orders]
      @total_employees  = data[:employees_stats][:total]
      @active_employees = data[:employees_stats][:active]
      @recent_employees = data[:employees_stats][:recent]

      # Carte « Solde disponible »
      @shop_balance   = data[:financial_stats][:balance]
      @pending_payout = data[:financial_stats][:pending_payout]
    end
  end
end
