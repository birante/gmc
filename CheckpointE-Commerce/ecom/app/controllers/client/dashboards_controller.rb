module Client
  class DashboardsController < BaseController
    PER_PAGE = 5

    def show
      @page = params[:page].to_i.positive? ? params[:page].to_i : 1
      @recent_orders = current_user.orders
                  .where.not(status: "pending")
                  .includes(:order_items, :delivery_zone, :currency)
                  .order(created_at: :desc)
                  .offset((@page - 1) * PER_PAGE)
                  .limit(PER_PAGE)
      @total_orders = current_user.orders_count
      @total_pages = (@total_orders.to_f / PER_PAGE).ceil
      @cart = current_cart
    end
  end
end
