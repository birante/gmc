# frozen_string_literal: true

class Admin::DashboardsController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_dates
  layout "admin_dashboard"

  # Le concern Trackable définit une méthode privée `analytics` qui entre en conflit
  # avec l'action publique `analytics` de ce contrôleur.
  # De plus, on ne tracke pas les pages admin.
  skip_before_action :setup_analytics_tracker, raise: false
  skip_after_action  :track_page_view_automatically, raise: false

  helper_method :filter_params, :d_start, :d_end

  # ─── GET /admin/hub ───────────────────────────────────────────────────────
  def index
    range      = @date_start.beginning_of_day..@date_end.end_of_day
    delta      = [ (@date_end - @date_start).to_i, 1 ].max
    prev_range = (@date_start - delta.days).beginning_of_day..(@date_start - 1.day).end_of_day

    # Filtre établissement
    @orders_base = Order.where(created_at: range)
    if params[:etablissement] == "principal"
      main_id = Shop.order(:id).limit(1).pluck(:id).first
      @orders_base = @orders_base.joins(:order_items).where(order_items: { shop_id: main_id }).distinct if main_id
    end

    # Tableau des commandes
    scope = @orders_base.includes(:user, :currency)
    scope = scope.where(status: params[:order_status]) if params[:order_status].present?
    sid   = params[:search_orders].to_s.gsub(/\D/, "")
    scope = scope.where(id: sid) if sid.present?
    scope = scope.order(created_at: params[:order_direction] == "asc" ? :asc : :desc)
    @orders_filtered    = scope.page(params[:page]).per(10)
    @orders_total_count = scope.count

    # KPIs courants
    @revenue          = @orders_base.where(status: "delivered").sum(:final_amount)
    @orders_count     = @orders_base.count
    @orders_delivered = @orders_base.where(status: "delivered").count
    @traffic          = ahoy_count(range)

    # KPIs période précédente
    orders_prev = Order.where(created_at: prev_range)
    @rev_prev   = orders_prev.where(status: "delivered").sum(:final_amount)
    @ord_prev   = orders_prev.count
    @traf_prev  = ahoy_count(prev_range)

    # Conversion
    @conversion = @traffic > 0 ? (@orders_delivered.to_f / @traffic * 100).round(2) : 0
    conv_prev_t = ahoy_count(prev_range)
    ord_prev_d  = orders_prev.where(status: "delivered").count
    @conv_prev  = conv_prev_t > 0 ? (ord_prev_d.to_f / conv_prev_t * 100).round(2) : 0

    # Alertes
    @alert_pending_orders   = Order.where(status: %w[pending processing]).count
    @alert_pending_products = Item.where(validation_status: "pending").count

    # Graphique CA par jour
    rev_raw         = @orders_base.where(status: "delivered").group("DATE(created_at)").sum(:final_amount)
    dates           = (@date_start..@date_end).to_a
    @revenue_by_day = dates.index_with { 0 }.merge(
      rev_raw.transform_keys { |k| k.respond_to?(:to_date) ? k.to_date : Date.parse(k.to_s) rescue Date.current }
    )

    # Logistique / paiements
    @logistics     = @orders_base.group(:status).count
    payments       = Payment.where(created_at: range)
    @pay_ok        = payments.completed.count
    @pay_wait      = payments.pending.count
    @pay_by_method = payments.joins(:payment_method).group("payment_methods.name").count

    # Stats produits
    @stats_pending  = Item.where(validation_status: "pending", created_at: range).count
    @stats_approved = Item.where(validation_status: "approved", created_at: range).count
    @stats_canceled = @orders_base.where(status: "canceled").count
    @catalogue_total = Item.where(created_at: range).count

    # Top produits
    sold_qty   = OrderItem.joins(:order).where(orders: { created_at: range }).group(:item_id).sum(:quantity)
    top_ids    = sold_qty.sort_by { |_, v| -v }.first(5).map(&:first)
    @top_items = Item.with_attached_main_image.includes(:currency, :variants)
                     .where(id: top_ids).index_by(&:id).values_at(*top_ids).compact
    @top_sold  = sold_qty

    # Top boutiques
    shop_ca      = OrderItem.joins(:order).where(orders: { created_at: range, status: "delivered" })
                            .group(:shop_id).sum("order_items.quantity * order_items.unit_price")
    top_shop_ids = shop_ca.sort_by { |_, v| -v }.first(5).map(&:first).compact
    @top_shops   = Shop.where(id: top_shop_ids).index_by(&:id).values_at(*top_shop_ids).compact
    @top_shops_ca = shop_ca

    # Ventes par catégorie
    @sales_by_cat = OrderItem.joins(:order, item: :product_sub_category)
                             .where(orders: { created_at: range, status: "delivered" })
                             .group("product_sub_categories.name").sum("order_items.quantity")

    @users_new = User.where(created_at: range).count
  end

  # ─── GET /admin/hub/analytics ─────────────────────────────────────────────
  def analytics
    range     = @date_start.beginning_of_day..@date_end.end_of_day
    nb_days   = [ (@date_end - @date_start).to_i, 1 ].max
    prev_start = @date_start - nb_days.days
    prev_range = prev_start.beginning_of_day..(@date_start - 1.day).end_of_day

    @total_visits   = Ahoy::Visit.where(started_at: range).count
    @unique_visits  = Ahoy::Visit.where(started_at: range).distinct.count(:visitor_token)
    @pages_vues     = Ahoy::Event.where(name: "page_viewed",        time: range).count
    @shops_vus      = Ahoy::Event.where(name: "shop_viewed",        time: range).count
    @items_vus      = Ahoy::Event.where(name: "item_viewed",        time: range).count
    @paniers        = Ahoy::Event.where(name: "item_added_to_cart", time: range).count
    @orders_ev      = Ahoy::Event.where(name: "order_completed",    time: range).count
    @conv_rate      = @shops_vus > 0 ? (@orders_ev.to_f / @shops_vus * 100).round(2) : 0

    @prev_visits    = Ahoy::Visit.where(started_at: prev_range).count
    @prev_pages     = Ahoy::Event.where(name: "page_viewed",  time: prev_range).count
    @prev_shops     = Ahoy::Event.where(name: "shop_viewed",  time: prev_range).count
    @prev_orders_ev = Ahoy::Event.where(name: "order_completed", time: prev_range).count

    @views_by_day  = Ahoy::Event.where(name: "page_viewed", time: range).group_by_day(:time, time_zone: "UTC").count
    @shop_by_day   = Ahoy::Event.where(name: "shop_viewed", time: range).group_by_day(:time, time_zone: "UTC").count

    @devices  = Ahoy::Visit.where(started_at: range).where.not(device_type: [ nil, "" ]).group(:device_type).count
    @browsers = Ahoy::Visit.where(started_at: range).where.not(browser: [ nil, "" ]).group(:browser).count.sort_by { |_, c| -c }.first(6)
    @sources  = Ahoy::Visit.where(started_at: range).where.not(utm_source: [ nil, "" ]).group(:utm_source).count.sort_by { |_, c| -c }.first(8)
    @countries = Ahoy::Visit.where(started_at: range).where.not(country: [ nil, "" ]).group(:country).count.sort_by { |_, c| -c }.first(15)

    all_pages    = Ahoy::Event.where(name: "page_viewed", time: range).group("properties->>'page_name'").count.sort_by { |_, c| -c }
    @top_pages   = Kaminari.paginate_array(all_pages).page(params[:page]).per(20)
    @total_views = Ahoy::Event.where(name: "page_viewed", time: range).count

    top_shops_data = begin
      Ahoy::Event.where(name: "shop_viewed", time: range).where.not(shop_id: nil)
                 .group(:shop_id).count.sort_by { |_, c| -c }.first(15)
    rescue StandardError; []
    end
    @analytics_top_shops = top_shops_data.filter_map do |shop_id, count|
      shop = Shop.find_by(id: shop_id)
      next unless shop
      { shop: shop, views: count }
    end

    top_items_data = begin
      Ahoy::Event.where(name: "item_viewed", time: range).where.not(item_id: nil)
                 .group(:item_id).count.sort_by { |_, c| -c }.first(15)
    rescue StandardError; []
    end
    @analytics_top_items = top_items_data.filter_map do |item_id, count|
      item = Item.find_by(id: item_id)
      next unless item
      { item: item, views: count }
    end

    @funnel = [
      { label: "Visites",      val: @total_visits, icon: "👣", color: "blue"   },
      { label: "Pages vues",   val: @pages_vues,   icon: "📄", color: "indigo" },
      { label: "Boutiques",    val: @shops_vus,    icon: "🏪", color: "purple" },
      { label: "Produits",     val: @items_vus,    icon: "🏷️", color: "orange" },
      { label: "Ajout panier", val: @paniers,      icon: "🛒", color: "amber"  },
      { label: "Commandes",    val: @orders_ev,    icon: "✅", color: "green"  }
    ]
  end

  # ─── GET /admin/hub/finance ───────────────────────────────────────────────
  def finance
    range = @date_start.beginning_of_day..@date_end.end_of_day

    @total_ca = Order.where(status: "delivered").where(created_at: range).sum(:final_amount)
    @total_orders = Order.where(created_at: range).count
    @delivered_orders = Order.where(status: "delivered", created_at: range).count
    @pending_amount = Order.where(status: %w[pending processing], created_at: range).sum(:final_amount)

    @ca_by_day = Order.where(status: "delivered", created_at: range)
                      .group("DATE(created_at)").sum(:final_amount)

    @revenue_distribution = Order.where(created_at: range)
                                 .group(:status).sum(:final_amount)
                                 .transform_keys { |k| k.humanize }

    @transactions = ShopTransaction.includes(:shop, :order, :payout, :currency)
                                   .where(created_at: range)
                                   .order(created_at: :desc)
                                   .page(params[:page]).per(15)

    @payouts_pending = Payout.where(status: "pending").count
    @payouts_paid    = Payout.where(status: "paid", updated_at: range).count
    @shop_balances   = Shop.active.includes(:currency, :vendor).order(balance: :desc).limit(10)

    @pay_methods = Payment.where(created_at: range).joins(:payment_method)
                          .group("payment_methods.name").count

    @recent_payouts = Payout.includes(:shop, :currency).order(created_at: :desc)
                             .where(created_at: range).limit(10)
  end

  private

  def set_dates
    @date_start = parse_date(params[:date_start] || params[:start_date]) || 30.days.ago.to_date
    @date_end   = parse_date(params[:date_end]   || params[:end_date])   || Date.current
    @date_end   = @date_start if @date_end < @date_start
  end

  def d_start = @date_start
  def d_end   = @date_end

  def filter_params
    { date_start: @date_start, date_end: @date_end,
      order_status: params[:order_status], search_orders: params[:search_orders],
      order_direction: params[:order_direction].presence || "desc",
      locale: params[:locale], etablissement: params[:etablissement] }.compact_blank
  end

  def parse_date(val)
    return nil if val.blank?
    Date.parse(val.to_s)
  rescue ArgumentError
    nil
  end

  def ahoy_count(range)
    return 0 unless defined?(Ahoy::Visit) && Ahoy::Visit.table_exists?
    Ahoy::Visit.where(started_at: range).count
  rescue StandardError; 0
  end
end
