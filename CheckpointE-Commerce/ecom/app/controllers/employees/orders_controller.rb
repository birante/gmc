module Employees
  class OrdersController < Employees::BaseController
    before_action :require_order_permission

    def index
      service = Employees::OrdersService.new(
        employee: @employee,
        shop_condition: "shops.id IN (?)",
        shop_value: current_scope_shop_ids
      )

      result = service.index(filters: params.slice(:status, :from, :to))
      @orders = result[:orders]
      @total_orders = result[:total_orders]
      @pending_orders = result[:pending_orders]
      @total_revenue = result[:total_revenue]
      @recent_orders_count = result[:recent_orders_count]
    end

    def show
      service = Employees::OrdersService.new(
        employee: @employee,
        shop_condition: "shops.id IN (?)",
        shop_value: current_scope_shop_ids
      )

      result = service.find_order(params[:id])
      if result
        @order = result[:order]
        @order_items = result[:order_items]
      else
        redirect_to employees_orders_path(shop_id: @current_shop&.id), alert: t("employees.orders.not_found")
      end
    end

    def update_status
      query = EmployeeOrdersQuery.new(
        employee: @employee,
        shop_condition: "shops.id IN (?)",
        shop_value: @employee.shops.pluck(:id)
      )

      result = query.find_with_order_items(params[:id])
      @order = result && result[:order]

      if @order && @order.update_status!(params[:new_status], changed_by: current_employee)
        # L'historique et departure_date sont gérés automatiquement par les callbacks AASM
        Rails.logger.info("[Employees::OrdersController] Statut commande mis à jour via AASM - order_id: #{@order.id}, nouveau_statut: #{params[:new_status]}, employee_id: #{current_employee.id}")
        redirect_to employees_order_path(@order, shop_id: @current_shop&.id), notice: t("employees.orders.status_updated")
      else
        Rails.logger.error("[Employees::OrdersController] Échec mise à jour statut commande - order_id: #{params[:id]}, employee_id: #{current_employee.id}")
        redirect_to employees_orders_path(shop_id: @current_shop&.id), alert: t("employees.orders.status_update_failed")
      end
    end

    def update_item_delivery_status
      query = EmployeeOrdersQuery.new(
        employee: @employee,
        shop_condition: "shops.id IN (?)",
        shop_value: current_scope_shop_ids
      )

      @order_item = query.find_order_item_for_update(params[:item_id])

      # Vérifier que la transition est valide
      if @order_item && @order_item.can_change_to_delivery_status?(params[:new_status])
        if @order_item.update(delivery_status: params[:new_status])
          Rails.logger.info("[Employees::OrdersController] Statut livraison mis à jour - order_item_id: #{@order_item.id}, ancien_statut: #{@order_item.delivery_status_was}, nouveau_statut: #{params[:new_status]}, employee_id: #{current_employee.id}")
          redirect_back(fallback_location: employees_order_path(@order_item.order, shop_id: @current_shop&.id), notice: t("employees.orders.delivery_status_updated"))
        else
          Rails.logger.error("[Employees::OrdersController] Échec mise à jour statut livraison (validation) - order_item_id: #{params[:item_id]}, employee_id: #{current_employee.id}, erreurs: #{@order_item.errors.full_messages.join(', ')}")
          redirect_back(fallback_location: employees_order_path(@order_item.order, shop_id: @current_shop&.id), alert: t("employees.orders.delivery_status_update_failed", errors: @order_item.errors.full_messages.join(", ")))
        end
      else
        Rails.logger.error("[Employees::OrdersController] Transition invalide - order_item_id: #{params[:item_id]}, statut_actuel: #{@order_item&.delivery_status}, nouveau_statut: #{params[:new_status]}, employee_id: #{current_employee.id}")
        redirect_back(fallback_location: employees_order_path(@order_item&.order, shop_id: @current_shop&.id), alert: t("employees.orders.invalid_transition"))
      end
    end

    private

    # Portée d'affichage : boutique active si sélectionnée, sinon toutes les boutiques assignées.
    def current_scope_shop_ids
      @current_shop ? [ @current_shop.id ] : @employee.shops.pluck(:id)
    end

    def require_order_permission
      unless current_employee.can_manage_orders?
        redirect_to employees_dashboard_path, alert: t("employees.orders.no_permission")
      end
    end
  end
end
