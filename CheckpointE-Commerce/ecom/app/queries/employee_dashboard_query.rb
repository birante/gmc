# frozen_string_literal: true

# Query pour les statistiques dashboard employee
#
# Usage:
#   query = EmployeeDashboardQuery.new(shop_condition: condition, shop_value: value)
#   revenue = query.revenue_by_period(start_date, end_date)
class EmployeeDashboardQuery
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

  def orders_count_since(date)
    Order.joins(order_items: :shop)
        .where(@shop_condition, @shop_value)
        .where("orders.created_at >= ?", date)
        .distinct
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

  def recent_orders_by_category(limit: 3)
    sub_categories_sold_raw = OrderItem.joins("JOIN items ON items.id = order_items.item_id")
                                       .joins("JOIN product_sub_categories ON product_sub_categories.id = items.product_sub_category_id")
                                       .joins("JOIN shops ON shops.id = order_items.shop_id")
                                       .where(@shop_condition, @shop_value)
                                       .group("product_sub_categories.id", "product_sub_categories.name", "product_sub_categories.slug")
                                       .count("order_items.id")
                                       .sort_by { |_, count| -count }
                                       .take(limit)

    sub_categories_sold_raw.map do |sub_cat_key, _count|
      sub_cat_id, sub_cat_name, sub_cat_slug = sub_cat_key

      order_items = OrderItem.joins("JOIN shops ON shops.id = order_items.shop_id")
                            .joins("JOIN items ON items.id = order_items.item_id")
                            .joins("JOIN product_sub_categories ON product_sub_categories.id = items.product_sub_category_id")
                            .joins("JOIN orders ON orders.id = order_items.order_id")
                            .where(@shop_condition, @shop_value)
                            .where("product_sub_categories.id = ?", sub_cat_id)
                            .includes(:item, :order)
                            .order("orders.created_at DESC")
                            .limit(10)

      {
        id: sub_cat_id,
        name: sub_cat_name,
        slug: sub_cat_slug,
        order_items: order_items
      }
    end
  end

  private

  attr_reader :shop_condition, :shop_value
end
