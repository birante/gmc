# frozen_string_literal: true

# Query pour lire les clients d'un vendor avec leurs statistiques
#
# Usage:
#   query = VendorClientsQuery.new(shop_condition: condition, shop_value: value)
#   clients = query.call
#   stats = query.stats
class VendorClientsQuery
  def initialize(shop_condition:, shop_value:)
    @shop_condition = shop_condition
    @shop_value = shop_value
  end

  def call
    User.joins(orders: :order_items)
        .joins("JOIN shops ON shops.id = order_items.shop_id")
        .where(@shop_condition, @shop_value)
        .select("users.id, users.first_name, users.last_name, users.email_address, users.phone_number, users.country_code, users.created_at, users.updated_at, COUNT(DISTINCT orders.id) as orders_count, SUM(order_items.total_price) as total_spent, MAX(orders.created_at) as last_order_date")
        .group("users.id, users.first_name, users.last_name, users.email_address, users.phone_number, users.country_code, users.created_at, users.updated_at")
        .order("last_order_date DESC")
  end

  def total_count
    User.joins(orders: :order_items)
        .joins("JOIN shops ON shops.id = order_items.shop_id")
        .where(@shop_condition, @shop_value)
        .distinct
        .count
  end

  def active_count(days: 30)
    User.joins(orders: :order_items)
        .joins("JOIN shops ON shops.id = order_items.shop_id")
        .where(@shop_condition, @shop_value)
        .where("orders.created_at >= ?", days.days.ago)
        .distinct
        .count
  end

  def find_client_orders(client_id:)
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where(user_id: client_id)
        .select("DISTINCT orders.*")
        .includes(:currency, :delivery_zone, :delivery_slot, order_items: [ :item, :shop ])
        .order("orders.created_at DESC")
  end

  def client_stats(client_id:)
    orders = find_client_orders(client_id: client_id)

    {
      total_orders: orders.count,
      total_spent: OrderItem.joins(:shop)
                           .where(@shop_condition, @shop_value)
                           .where(order_id: orders.pluck(:id))
                           .sum(:total_price) || 0,
      first_order_date: orders.minimum(:created_at),
      last_order_date: orders.maximum(:created_at)
    }
  end

  def client_exists?(client_id:)
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where(user_id: client_id)
        .exists?
  end

  private

  attr_reader :shop_condition, :shop_value
end
