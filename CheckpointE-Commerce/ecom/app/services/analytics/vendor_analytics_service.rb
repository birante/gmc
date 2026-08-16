# frozen_string_literal: true

module Analytics
  class VendorAnalyticsService
    PER_PAGE = 20

    def initialize(shop, start_date, end_date, page: 1)
      @shop = shop
      @start_date = start_date
      @end_date = end_date
      @time_range = start_date.beginning_of_day..end_date.end_of_day
      @page = page
    end

    def overview_data
      {
        shop_views: shop_views,
        unique_visitors: unique_visitors,
        items_views: items_views,
        items_added_to_cart: items_added_to_cart,
        orders_count: orders_count,
        revenue: revenue,
        conversion_rate: conversion_rate,
        shop_views_by_day: shop_views_by_day,
        top_viewed_items: top_viewed_items
      }
    end

    def products_data
      # Récupérer tous les items avec leurs stats
      items_with_stats = @shop.items.includes(:product_sub_category).map do |item|
        {
          item: item,
          views: item_views(item),
          added_to_cart: item_added_to_cart(item),
          orders: item_orders_count(item),
          revenue: item_revenue(item)
        }
      end.sort_by { |stat| -stat[:views] }

      # Paginer manuellement car on a déjà un array
      Kaminari.paginate_array(items_with_stats).page(@page).per(PER_PAGE)
    end

    def orders_data
      shop_order_ids = OrderItem.joins(:item)
        .where(items: { shop_id: @shop.id })
        .distinct
        .pluck(:order_id)

      shop_orders = Order.where(id: shop_order_ids, created_at: @time_range)

      orders_by_day_data = shop_orders.group_by_day(:created_at, time_zone: "UTC").count

      # Normaliser toutes les clés en String pour éviter les erreurs de comparaison
      orders_by_day_data = orders_by_day_data.transform_keys { |key| key.is_a?(String) ? key : key.strftime("%Y-%m-%d") }

      # Remplir les dates manquantes avec 0
      (@start_date..@end_date).each do |date|
        date_key = date.strftime("%Y-%m-%d")
        orders_by_day_data[date_key] ||= 0
      end

      {
        orders_by_status: shop_orders.group(:status).count,
        orders_by_day: orders_by_day_data.sort.to_h,
        revenue_by_day: revenue_by_day,
        average_order_value: average_order_value
      }
    end

    def traffic_data
      {
        traffic_sources: traffic_sources,
        devices: devices,
        browsers: browsers
      }
    end

    private

    def shop_views
      Ahoy::Event
        .where(name: "shop_viewed", shop_id: @shop.id)
        .where(time: @time_range)
        .count
    end

    def unique_visitors
      Ahoy::Event
        .where(name: "shop_viewed", shop_id: @shop.id)
        .where(time: @time_range)
        .distinct
        .count(:visit_id)
    end

    def items_views
      Ahoy::Event
        .where(name: "item_viewed", shop_id: @shop.id)
        .where(time: @time_range)
        .count
    end

    def items_added_to_cart
      Ahoy::Event
        .where(name: "item_added_to_cart", shop_id: @shop.id)
        .where(time: @time_range)
        .count
    end

    def orders_count
      shop_order_ids = OrderItem.joins(:item)
        .where(items: { shop_id: @shop.id })
        .distinct
        .pluck(:order_id)

      Order
        .where(id: shop_order_ids, created_at: @time_range)
        .count
    end

    def revenue
      OrderItem.joins(:item, :order)
        .where(items: { shop_id: @shop.id })
        .where(orders: { created_at: @time_range, status: [ "processing", "shipped", "delivered" ] })
        .sum(:total_price)
    end

    def conversion_rate
      views = shop_views
      views > 0 ? ((orders_count.to_f / views) * 100).round(2) : 0
    end

    def shop_views_by_day
      data = Ahoy::Event
        .where(name: "shop_viewed", shop_id: @shop.id)
        .where(time: @time_range)
        .group_by_day(:time, time_zone: "UTC")
        .count

      # Normaliser toutes les clés en String pour éviter les erreurs de comparaison
      data = data.transform_keys { |key| key.is_a?(String) ? key : key.strftime("%Y-%m-%d") }

      # Remplir les dates manquantes avec 0 pour avoir un graphique complet
      (@start_date..@end_date).each do |date|
        date_key = date.strftime("%Y-%m-%d")
        data[date_key] ||= 0
      end

      data.sort.to_h
    end

    def top_viewed_items
      viewed_items = Ahoy::Event
        .where(name: "item_viewed", shop_id: @shop.id)
        .where(time: @time_range)
        .where.not(item_id: nil)
        .group(:item_id)
        .count
        .sort_by { |_id, count| -count }
        .first(5)
        .map { |item_id, count| { item: Item.find_by(id: item_id), count: count } }
        .compact

      # Si aucun produit n'a été vu, afficher les 5 produits les plus récents de la boutique
      if viewed_items.empty? && @shop.items.any?
        @shop.items.order(created_at: :desc).limit(5).map do |item|
          { item: item, count: 0 }
        end
      else
        viewed_items
      end
    end

    def item_views(item)
      Ahoy::Event
        .where(name: "item_viewed", item_id: item.id)
        .where(time: @time_range)
        .count
    end

    def item_added_to_cart(item)
      Ahoy::Event
        .where(name: "item_added_to_cart", item_id: item.id)
        .where(time: @time_range)
        .count
    end

    def item_orders_count(item)
      item.order_items
        .joins(:order)
        .where(orders: { created_at: @time_range })
        .count
    end

    def item_revenue(item)
      item.order_items
        .joins(:order)
        .where(orders: { created_at: @time_range, status: [ "processing", "shipped", "delivered" ] })
        .sum(:total_price)
    end

    def revenue_by_day
      data = OrderItem.joins(:item, :order)
        .where(items: { shop_id: @shop.id })
        .where(orders: { created_at: @time_range, status: [ "processing", "shipped", "delivered" ] })
        .group_by_day("orders.created_at", time_zone: "UTC")
        .sum(:total_price)

      # Normaliser toutes les clés en String pour éviter les erreurs de comparaison
      data = data.transform_keys { |key| key.is_a?(String) ? key : key.strftime("%Y-%m-%d") }

      # Remplir les dates manquantes avec 0
      (@start_date..@end_date).each do |date|
        date_key = date.strftime("%Y-%m-%d")
        data[date_key] ||= 0
      end

      data.sort.to_h
    end

    def average_order_value
      total_revenue = OrderItem.joins(:item, :order)
        .where(items: { shop_id: @shop.id })
        .where(orders: { created_at: @time_range, status: [ "processing", "shipped", "delivered" ] })
        .sum(:total_price)

      shop_orders = @shop.orders.where(created_at: @time_range)
      counted_orders = shop_orders.where(status: [ "processing", "shipped", "delivered" ]).count

      counted_orders > 0 ? (total_revenue.to_f / counted_orders).round(2) : 0.0
    end

    def traffic_sources
      Ahoy::Event
        .joins(:visit)
        .where(name: "shop_viewed", shop_id: @shop.id)
        .where(time: @time_range)
        .where.not(ahoy_visits: { utm_source: [ nil, "" ] })
        .group("ahoy_visits.utm_source")
        .count
        .sort_by { |_source, count| -count }
    end

    def devices
      Ahoy::Visit
        .joins(:events)
        .where(ahoy_events: { name: "shop_viewed", shop_id: @shop.id, time: @time_range })
        .where.not(device_type: [ nil, "" ])
        .group(:device_type)
        .count
    end

    def browsers
      Ahoy::Visit
        .joins(:events)
        .where(ahoy_events: { name: "shop_viewed", shop_id: @shop.id, time: @time_range })
        .where.not(browser: [ nil, "" ])
        .group(:browser)
        .count
        .sort_by { |_browser, count| -count }
        .first(5)
    end
  end
end
