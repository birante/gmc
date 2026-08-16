# frozen_string_literal: true

# Query pour lire les commandes accessibles à un collaborateur.
#
# Calquée sur VendorOrdersQuery (même API publique), mais :
#  - la portée est limitée aux boutiques assignées au collaborateur,
#    exprimée via shop_condition = "shops.id IN (?)" et shop_value = shop_ids ;
#  - les commandes 'pending' restent visibles (le collaborateur doit les traiter),
#    contrairement au vendor qui les exclut par défaut.
#
# Usage:
#   query = EmployeeOrdersQuery.new(employee: employee, shop_condition: condition, shop_value: value)
#   orders = query.call(filters: { status: 'pending', from: 1.week.ago })
class EmployeeOrdersQuery
  def initialize(employee:, shop_condition:, shop_value:)
    @employee = employee
    @shop_condition = shop_condition
    @shop_value = shop_value
  end

  def call(filters: {})
    orders = base_scope

    orders = orders.where(status: filters[:status]) if filters[:status].present?
    orders = orders.where("orders.created_at >= ?", filters[:from]) if filters[:from].present?
    orders = orders.where("orders.created_at <= ?", filters[:to]) if filters[:to].present?

    orders
  end

  def total_count
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .distinct
        .count
  end

  def pending_count
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where(orders: { status: "pending" })
        .distinct
        .count
  end

  def total_revenue
    OrderItem.joins(:shop)
            .where(@shop_condition, @shop_value)
            .sum(:total_price) || 0
  end

  def recent_count(days: 7)
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where("orders.created_at >= ?", days.days.ago)
        .distinct
        .count
  end

  def find_with_order_items(order_id)
    order = Order.includes(:user, :currency, :delivery_zone, :delivery_slot, order_items: [ :item, :shop ])
                 .friendly.find(order_id)

    # Vérifier que le collaborateur a accès à au moins un item de cette commande
    accessible_items = order.order_items.joins(:shop)
                          .where(@shop_condition, @shop_value)

    return nil if accessible_items.empty?

    # Retourner la commande avec les order_items filtrés sur ses boutiques
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

  def find_order_item_for_update(item_id)
    OrderItem.joins(:shop)
            .where(id: item_id)
            .where(@shop_condition, @shop_value)
            .first
  end

  private

  attr_reader :employee, :shop_condition, :shop_value

  def base_scope
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .select("DISTINCT orders.*")
        .includes(:user, :currency, order_items: [ :item, :shop ])
        .order("orders.created_at DESC")
  end
end
