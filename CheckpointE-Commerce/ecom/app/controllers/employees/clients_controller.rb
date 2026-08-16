module Employees
  # Clients (lecture) côté collaborateur : liste les clients qui ont commandé sur les
  # boutiques accessibles au collaborateur. Identique au flux Vendors::ClientsController
  # mais filtré par le shop_condition fourni par EmployeeShopContext.
  class ClientsController < Employees::BaseController
    before_action :set_client, only: [ :show ]

    def index
      clients_query = VendorClientsQuery.new(shop_condition: @shop_condition, shop_value: @shop_value)
      orders_query  = VendorOrdersQuery.new(vendor: @vendor, shop_condition: @shop_condition, shop_value: @shop_value)

      @clients        = clients_query.call
      @total_clients  = clients_query.total_count
      @active_clients = clients_query.active_count
      @total_orders   = orders_query.total_count
      @total_revenue  = orders_query.total_revenue
    end

    def show
      return unless @client

      clients_query = VendorClientsQuery.new(shop_condition: @shop_condition, shop_value: @shop_value)
      @orders = clients_query.find_client_orders(client_id: @client.id)

      unless @orders.any?
        redirect_to employees_clients_path(shop_id: @current_shop&.id), alert: "Aucune commande trouvée pour ce client"
        return
      end

      stats = clients_query.client_stats(client_id: @client.id)
      @client_total_orders = stats[:total_orders]
      @client_total_spent  = stats[:total_spent]
      @first_order_date    = stats[:first_order_date]
      @last_order_date     = stats[:last_order_date]
    end

    private

    def set_client
      @client = UsersQuery.find_by_id(params[:id])
      clients_query = VendorClientsQuery.new(shop_condition: @shop_condition, shop_value: @shop_value)

      unless @client && clients_query.client_exists?(client_id: @client.id)
        redirect_to employees_clients_path(shop_id: @current_shop&.id), alert: "Client non trouvé"
      end
    end
  end
end
