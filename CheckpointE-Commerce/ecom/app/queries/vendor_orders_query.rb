# frozen_string_literal: true

# Query pour lire les commandes d'un vendor avec filtres
#
# Usage:
#   query = VendorOrdersQuery.new(vendor: vendor, shop_condition: condition, shop_value: value)
#   orders = query.call(filters: { status: 'pending', from: 1.week.ago })
class VendorOrdersQuery
    # Pour transmettre les filtres aux méthodes de stats
    def set_filters(filters)
      @filters = filters
    end
  def initialize(vendor:, shop_condition:, shop_value:)
    @vendor = vendor
    @shop_condition = shop_condition
    @shop_value = shop_value
  end

  def call(filters: {})
    orders = base_scope

    # Exclure les commandes 'pending' sauf si le filtre explicite est demandé
    if filters[:status].present?
      orders = orders.where(status: filters[:status])
    else
      orders = orders.where.not(status: "pending")
    end

    orders = orders.where("orders.created_at >= ?", filters[:from]) if filters[:from].present?
    orders = orders.where("orders.created_at <= ?", filters[:to]) if filters[:to].present?

    orders
  end

  def total_count
    scope = Order.joins(order_items: :shop)
                 .where(@shop_condition, @shop_value)
    # Exclure 'pending' sauf si filtre explicite
    if defined?(@filters) && @filters && @filters[:status].present?
      scope = scope.where(status: @filters[:status])
    else
      scope = scope.where.not(status: "pending")
    end
    scope.distinct.count
  end

  def pending_count
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where(orders: { status: "pending" })
        .distinct
        .count
  end

  def total_revenue
    # On ne compte que les order_items liés à des commandes non-pending (sauf filtre explicite)
    order_scope = Order.joins(order_items: :shop)
                      .where(@shop_condition, @shop_value)
    if defined?(@filters) && @filters && @filters[:status].present?
      order_scope = order_scope.where(status: @filters[:status])
    else
      order_scope = order_scope.where.not(status: "pending")
    end
    order_ids = order_scope.distinct.pluck(:id)
    OrderItem.where(order_id: order_ids).sum(:total_price) || 0
  end

  def recent_count(days: 7)
    scope = Order.joins(order_items: :shop)
                 .where(@shop_condition, @shop_value)
                 .where("orders.created_at >= ?", days.days.ago)
    if defined?(@filters) && @filters && @filters[:status].present?
      scope = scope.where(status: @filters[:status])
    else
      scope = scope.where.not(status: "pending")
    end
    scope.distinct.count
  end

  def find_with_order_items(order_id)
    order = Order.includes(:user, :currency, :delivery_zone, :delivery_slot, order_items: [ :item, :shop ])
                 .friendly.find(order_id)

    # Vérifier que cette commande appartient bien au vendor
    accessible_items = order.order_items.joins(:shop)
                          .where(@shop_condition, @shop_value)

    return nil if accessible_items.empty?

    # Retourner la commande avec les order_items filtrés
    order_items = order.order_items.joins(:shop)
                      .where(@shop_condition, @shop_value)
                      .includes(:item, :shop)

    {
      order: order,
      order_items: order_items
    }
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  attr_reader :vendor, :shop_condition, :shop_value

  def base_scope
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .select("DISTINCT orders.*")
        .includes(:user, :currency, order_items: [ :item, :shop ])
        .order("orders.created_at DESC")
  end
end
