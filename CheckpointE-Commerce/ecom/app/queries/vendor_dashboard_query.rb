# frozen_string_literal: true

# Query pour les statistiques dashboard vendor (revenus, items, carts, users)
#
# Usage:
#   query = VendorDashboardQuery.new(shop_condition: condition, shop_value: value)
#   revenue = query.revenue_by_period(start_date, end_date)
class VendorDashboardQuery
  def initialize(shop_condition:, shop_value:)
    @shop_condition = shop_condition
    @shop_value = shop_value
  end

  def revenue_by_period(start_date, end_date)
    OrderItem.joins(:shop, :order)
            .where(@shop_condition, @shop_value)
            .where("orders.created_at >= ? AND orders.created_at < ?", start_date, end_date)
            .sum(:total_price) || 0
  end

  def revenue_since(date)
    OrderItem.joins(:shop, :order)
            .where(@shop_condition, @shop_value)
            .where("orders.created_at >= ?", date)
            .sum(:total_price) || 0
  end

  def orders_count_by_period(start_date, end_date)
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where("orders.created_at >= ? AND orders.created_at < ?", start_date, end_date)
        .distinct
        .count
  end

  def orders_count_since(date)
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where("orders.created_at >= ?", date)
        .distinct
        .count
  end

  def items_count_before(date)
    Item.joins(:shop)
       .where(@shop_condition, @shop_value)
       .where("items.created_at < ?", date)
       .count
  end

  def carts_abandoned_by_period(start_date, end_date)
    Cart.where.not(status: "active")
       .where("created_at >= ? AND created_at < ?", start_date, end_date)
       .count
  end

  def carts_abandoned_since(date)
    Cart.where.not(status: "active")
       .where("created_at >= ?", date)
       .count
  end

  def new_clients_since(date)
    User.joins(orders: :order_items)
       .joins("JOIN shops ON shops.id = order_items.shop_id")
       .where(@shop_condition, @shop_value)
       .where("users.created_at >= ?", date)
       .distinct
       .count
  end

  def top_items_by_sales(limit: 3)
    OrderItem.joins(:shop, :item)
            .where(@shop_condition, @shop_value)
            .group("items.name", "items.id")
            .sum(:quantity)
            .sort_by { |_, v| -v }
            .first(limit)
  end

  def weekly_sales_by_days(start_date, days: 7)
    (0..(days - 1)).map do |day_offset|
      day_start = start_date + day_offset.days
      day_end = day_start + 1.day

      OrderItem.joins(:shop, :order)
              .where(@shop_condition, @shop_value)
              .where("orders.created_at >= ? AND orders.created_at < ?", day_start, day_end)
              .sum(:quantity) || 0
    end
  end

  def recent_clients(limit: 6, since: 1.month.ago)
    User.joins(orders: :order_items)
       .joins("JOIN shops ON shops.id = order_items.shop_id")
       .where(@shop_condition, @shop_value)
       .where("orders.created_at >= ?", since)
       .group("users.id", "users.first_name", "users.last_name")
       .order("COUNT(orders.id) DESC")
       .limit(limit)
       .pluck(:first_name, :last_name)
  end

  def recent_orders(shop_ids:, limit: 10)
    Order.joins(:order_items)
        .where("order_items.shop_id IN (?)", shop_ids)
        .includes(:user, :delivery_zone, :delivery_slot, order_items: [ :item, :shop ])
        .distinct
        .order(created_at: :desc)
        .limit(limit)
  end

  def recent_items(limit: 8)
    Item.joins(:shop)
       .where(@shop_condition, @shop_value)
       .includes(:product_sub_category, :currency, :shop, :variants, :main_image_attachment, :images_attachments)
       .order(created_at: :desc)
       .limit(limit)
  end

  private

  attr_reader :shop_condition, :shop_value
end
