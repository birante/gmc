class Vendors::DashboardsController < Vendors::BaseController
  before_action :ensure_subscription_exists, only: [ :show ]

  def show
    @vendor = current_vendor
    return unless @vendor

    # Utiliser le service pour orchestrer le chargement de toutes les données
    service = Vendors::DashboardDataService.new(
      vendor: @vendor,
      shop_condition: @shop_condition,
      shop_value: @shop_value,
      current_shop: @current_shop
    )

    data = service.call

    # Mapper les données du service aux variables d'instance
    @shops = data[:shops]
    @total_shops = data[:shops_stats][:total]
    @active_shops = data[:shops_stats][:active]
    @pending_shops = data[:shops_stats][:pending]
    @total_items = data[:items_stats][:total]
    @recent_orders = data[:recent_orders]
    @total_orders = data[:orders_stats][:total]
    @pending_orders = data[:orders_stats][:pending]
    @total_revenue = data[:revenue_stats][:total]
    @last_month_revenue = data[:revenue_stats][:last_month]
    @current_month_revenue = data[:revenue_stats][:current_month]
    @stats = data[:stats]
    @top_articles = data[:top_articles]
    @weekly_data = data[:weekly_data]
    @shop_balance = data[:financial_stats][:balance]
    @pending_payout = data[:financial_stats][:pending_payout]
    @total_employees = data[:employees_stats][:total]
    @active_employees = data[:employees_stats][:active]
    @recent_employees = data[:employees_stats][:recent]
    @top_clients = data[:top_clients]
    @recent_items = data[:recent_items]

    Rails.logger.info "🏷️ [Dashboard] vendor_id: #{@vendor.id}, current_shop_id: #{@current_shop&.id}, total_items: #{@total_items}"
  end

  private

  def ensure_subscription_exists
    return unless @current_shop

    unless @current_shop.current_subscription
      # Vérifier que le vendeur a bien une boutique avant de rediriger
      if current_vendor&.shops&.any?
        redirect_to new_vendors_plan_path, alert: t("vendors.plans.subscription_required")
      end
    end
  end
end
