class Vendors::OrdersController < Vendors::BaseController
  def index
    @vendor = current_vendor
    return initialize_empty_orders unless @vendor

    @shops = @vendor.shops.includes(:items).order(created_at: :desc)

    shop_condition = @shop_condition || "shops.vendor_id = ?"
    shop_value = @shop_value || @vendor.id

    service = Vendors::OrdersService.new(
      vendor: @vendor,
      shop_condition: shop_condition,
      shop_value: shop_value
    )

    result = service.index(filters: params.slice(:status, :from, :to))
    @orders = result[:orders]
    @total_orders = result[:total_orders]
    @pending_orders = result[:pending_orders]
    @total_revenue = result[:total_revenue]
    @recent_orders_count = result[:recent_orders_count]
  end

  def show
    @vendor = current_vendor
    return unless @vendor

    @shops = @vendor.shops.order(created_at: :desc)

    shop_condition = @shop_condition || "shops.vendor_id = ?"
    shop_value = @shop_value || @vendor.id

    service = Vendors::OrdersService.new(
      vendor: @vendor,
      shop_condition: shop_condition,
      shop_value: shop_value
    )

    result = service.find_order(params[:id])
    if result
      @order = result[:order]
      @order_items = result[:order_items]
    else
      redirect_to vendors_orders_path(shop_slug: @current_shop&.slug || params[:shop_slug]), alert: "Commande non trouvée"
    end
  end

  # NOTE: update_status a été supprimé car le statut de la commande est maintenant
  # calculé automatiquement à partir des statuts des articles (order_items)
  # Les vendeurs ne peuvent plus modifier manuellement le statut de la commande

  def update_item_delivery_status
    @vendor = current_vendor
    shop_condition = @shop_condition || "shops.vendor_id = ?"
    shop_value = @shop_value || @vendor.id

    access_service = Vendors::OrderAccessService.new(
      vendor: @vendor,
      shop_condition: shop_condition,
      shop_value: shop_value
    )

    access_result = access_service.check_order_item_access(params[:item_id])
    shop_slug = @current_shop&.slug || params[:shop_slug]

    unless access_result[:accessible]
      redirect_to vendors_orders_path(shop_slug: shop_slug), alert: "Article de commande non trouvé"
      return
    end

    @order_item = access_result[:order_item]

    unless @order_item.can_change_to_delivery_status?(params[:new_status])
      redirect_back(fallback_location: vendors_order_path(@order_item.order, shop_slug: shop_slug), alert: "Transition de statut invalide")
      return
    end

    if @order_item.update(delivery_status: params[:new_status])
      Rails.logger.info("🚚 [Vendors::OrdersController] Statut livraison mis à jour - order_item_id: #{@order_item.id}, nouveau_statut: #{params[:new_status]}")

      # Recharger la commande pour obtenir le statut mis à jour
      @order_item.order.reload

      # Vérifier que le statut de la commande a été mis à jour automatiquement
      Rails.logger.info("📊 [Vendors::OrdersController] Statut commande après mise à jour - order_id: #{@order_item.order.id}, statut: #{@order_item.order.status}")

      redirect_back(fallback_location: vendors_order_path(@order_item.order, shop_slug: shop_slug), notice: "Statut de livraison mis à jour")
    else
      Rails.logger.error("❌ [Vendors::OrdersController] Échec mise à jour - erreurs: #{@order_item.errors.full_messages.join(', ')}")
      redirect_back(fallback_location: vendors_order_path(@order_item.order, shop_slug: shop_slug), alert: "Impossible de mettre à jour le statut: #{@order_item.errors.full_messages.join(', ')}")
    end
  end

  def upgrade_plan
    return redirect_to vendors_dashboard_path(shop_slug: @current_shop&.slug), alert: I18n.t("vendors.plans.shop_required") unless @current_shop

    plan = Plan.find_by(id: params[:plan_id], is_active: true)
    unless plan
      redirect_to url_with_shop(vendors_orders_path, @current_shop),
                  alert: I18n.t("vendors.plans.invalid_plan")
      return
    end

    service = Vendors::UpgradePlanService.new(shop: @current_shop, new_plan: plan)
    result = service.call

    if result.success?
      redirect_to url_with_shop(vendors_orders_path, @current_shop),
                  notice: I18n.t("vendors.plans.upgrade_success", plan_name: plan.name)
    else
      redirect_to url_with_shop(vendors_orders_path, @current_shop),
                  alert: result.errors.join(", ")
    end
  end

  private

  def initialize_empty_orders
    @orders = Order.none
    @total_orders = 0
    @pending_orders = 0
    @total_revenue = 0
    @recent_orders_count = 0
  end
end
