# frozen_string_literal: true

module Employees
  class AnalyticsController < Employees::BaseController
    before_action :set_shop
    before_action :set_date_range
    before_action :set_analytics_service

    def index
      @active_tab = params[:tab] || "overview"

      case @active_tab
      when "overview"
        load_overview_data
      when "products"
        load_products_data
      when "orders"
        load_orders_data
      when "traffic"
        load_traffic_data
      end
    end

    private

    def set_shop
      @shop = current_employee.shops.friendly.find(params[:shop_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to employees_dashboard_path, alert: t("employees.analytics.shop_not_found")
    end

    def set_date_range
      @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 7.days.ago.to_date
      @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
    rescue ArgumentError
      @start_date = 7.days.ago.to_date
      @end_date = Date.today
    end

    def set_analytics_service
      @analytics_service = Analytics::EmployeeAnalyticsService.new(@shop, @start_date, @end_date, page: params[:page])
    end

    def load_overview_data
      data = @analytics_service.overview_data
      @shop_views = data[:shop_views]
      @unique_visitors = data[:unique_visitors]
      @items_views = data[:items_views]
      @items_added_to_cart = data[:items_added_to_cart]
      @orders_count = data[:orders_count]
      @revenue = data[:revenue]
      @conversion_rate = data[:conversion_rate]
      @shop_views_by_day = data[:shop_views_by_day]
      @top_viewed_items = data[:top_viewed_items]
    end

    def load_products_data
      @products_stats = @analytics_service.products_data
    end

    def load_orders_data
      data = @analytics_service.orders_data
      @orders_by_status = data[:orders_by_status]
      @orders_by_day = data[:orders_by_day]
      @revenue_by_day = data[:revenue_by_day]
      @average_order_value = data[:average_order_value]
    end

    def load_traffic_data
      data = @analytics_service.traffic_data
      @traffic_sources = data[:traffic_sources]
      @devices = data[:devices]
      @browsers = data[:browsers]
    end
  end
end
