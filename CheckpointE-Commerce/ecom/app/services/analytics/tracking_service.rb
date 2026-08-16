# frozen_string_literal: true

module Analytics
  class TrackingService
    include EventDefinitions

    attr_reader :trackers

    def initialize(user: nil, visit: nil, context: {}, controller: nil)
      @user = user
      @visit = visit
      @context = context
      @controller = controller
      @trackers = build_trackers
    end

    # Track une page vue
    def track_page_view(page_name, properties = {})
      track_event(Events::PAGE_VIEWED, properties.merge(page_name: page_name))
    end

    # Track un événement avec validation
    def track_event(event_name, properties = {})
      return unless Analytics.enabled?

      track_start = Time.current

      # Valider l'événement en développement
      if Analytics.configuration.debug_mode
        unless EventDefinitions.valid_event?(event_name)
          Rails.logger.warn("⚠️ [Analytics::TrackingService] Événement inconnu: #{event_name}")
        else
          Rails.logger.debug("✅ [Analytics::TrackingService] Événement valide: #{event_name}")
        end
      end

      event_data = build_event_data(event_name, properties)

      if Analytics.configuration.debug_mode
        Rails.logger.info("📊 [Analytics::TrackingService] Tracking - Event: #{event_name} | User: #{@user&.class&.name}##{@user&.id}")
        Rails.logger.debug("🔍 [Analytics::TrackingService] Properties: #{properties.inspect}")
      end

      if Analytics.configuration.async_tracking
        current_visit_id = @visit&.id
        TrackEventJob.perform_later(event_name, event_data, visit_id: current_visit_id)
        track_duration = (Time.current - track_start).round(3)
        Rails.logger.debug("⏱️ [Analytics::TrackingService] Job enqueueé en #{track_duration}s - Event: #{event_name}") if Analytics.configuration.debug_mode
      else
        send_to_trackers(event_name, event_data)
        track_duration = (Time.current - track_start).round(3)
        Rails.logger.debug("⏱️ [Analytics::TrackingService] Tracking sync en #{track_duration}s - Event: #{event_name}") if Analytics.configuration.debug_mode
      end
    rescue => e
      track_duration = (Time.current - track_start).round(3)
      Rails.logger.error("❌ [Analytics::TrackingService] Erreur tracking après #{track_duration}s - Event: #{event_name} | #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Analytics::TrackingService] Backtrace: #{e.backtrace.first(3).join('\n')}")
    end

    # Track la vue d'une boutique
    def track_shop_view(shop, properties = {})
      Rails.logger.info("🏪 [Analytics::TrackingService] Shop viewed - ID: #{shop.id} | Name: #{shop.name}") if Analytics.configuration.debug_mode

      event_data = {
        Properties::SHOP_ID => shop.id,
        Properties::SHOP_NAME => shop.name,
        Properties::SHOP_SLUG => shop.slug,
        Properties::VENDOR_ID => shop.vendor_id
      }.merge(properties)

      track_event(Events::SHOP_VIEWED, event_data)
      shop.increment_view_count
    end

    # Track la vue d'un produit
    def track_item_view(item, properties = {})
      Rails.logger.info("📦 [Analytics::TrackingService] Item viewed - ID: #{item.id} | Name: #{item.name} | Price: #{item.price}") if Analytics.configuration.debug_mode

      event_data = {
        Properties::ITEM_ID => item.id,
        Properties::ITEM_NAME => item.name,
        Properties::ITEM_PRICE => item.price,
        Properties::SHOP_ID => item.shop_id,
        Properties::SHOP_NAME => item.shop.name,
        Properties::ITEM_CATEGORY => item.product_category&.name,
        Properties::ITEM_SUB_CATEGORY => item.product_sub_category&.name
      }.merge(properties)

      track_event(Events::ITEM_VIEWED, event_data)
      item.increment_view_count
    end

    # Track un ajout au panier
    def track_add_to_cart(item, quantity: 1, properties: {})
      Rails.logger.info("🛒 [Analytics::TrackingService] Add to cart - Item: #{item.id} | Qty: #{quantity}") if Analytics.configuration.debug_mode

      event_data = {
        Properties::ITEM_ID => item.id,
        Properties::ITEM_NAME => item.name,
        Properties::ITEM_PRICE => item.price,
        Properties::QUANTITY => quantity,
        Properties::SHOP_ID => item.shop_id
      }.merge(properties)

      track_event(Events::ITEM_ADDED_TO_CART, event_data)
    end

    # Track un retrait du panier
    def track_remove_from_cart(item, quantity: 1, properties: {})
      event_data = {
        Properties::ITEM_ID => item.id,
        Properties::ITEM_NAME => item.name,
        Properties::QUANTITY => quantity,
        Properties::SHOP_ID => item.shop_id
      }.merge(properties)

      track_event(Events::ITEM_REMOVED_FROM_CART, event_data)
    end

    # Track le début du checkout
    def track_checkout_started(cart, properties = {})
      event_data = {
        Properties::CART_TOTAL => cart.total,
        Properties::CART_ITEMS_COUNT => cart.cart_items.count
      }.merge(properties)

      track_event(Events::CHECKOUT_STARTED, event_data)
    end

    # Track une commande
    def track_order_completed(order, properties = {})
      Rails.logger.info("✅ [Analytics::TrackingService] Order completed - ID: #{order.id} | Number: #{order.number} | Total: #{order.total_amount}") if Analytics.configuration.debug_mode

      event_data = {
        Properties::ORDER_ID => order.id,
        Properties::ORDER_NUMBER => order.number,
        Properties::ORDER_TOTAL => order.total_amount,
        Properties::SHOP_ID => order.shop_id,
        Properties::ORDER_ITEMS_COUNT => order.order_items.count
      }.merge(properties)

      track_event(Events::ORDER_COMPLETED, event_data)
    end

    # Track une recherche de boutique
    def track_shop_search(query, results_count: 0, properties: {})
      event_data = {
        query: query,
        results_count: results_count
      }.merge(properties)

      track_event(Events::SHOP_SEARCHED, event_data)
    end

    # Track une recherche de produit
    def track_item_search(query, results_count: 0, properties: {})
      event_data = {
        query: query,
        results_count: results_count
      }.merge(properties)

      track_event(Events::ITEM_SEARCHED, event_data)
    end

    # ==========================================
    # TRACKING SPÉCIFIQUE PAR TYPE D'UTILISATEUR
    # ==========================================

    # --- VENDEUR ---

    def track_vendor_shop_created(shop, properties = {})
      event_data = {
        Properties::SHOP_ID => shop.id,
        Properties::SHOP_NAME => shop.name,
        Properties::SHOP_STATUS => shop.status
      }.merge(properties)

      track_event(Events::VENDOR_SHOP_CREATED, event_data)
    end

    def track_vendor_product_created(item, properties = {})
      event_data = {
        Properties::ITEM_ID => item.id,
        Properties::ITEM_NAME => item.name,
        Properties::ITEM_PRICE => item.default_variant&.price,
        Properties::SHOP_ID => item.shop_id
      }.merge(properties)

      track_event(Events::VENDOR_PRODUCT_CREATED, event_data)
    end

    def track_vendor_product_updated(item, changes = {}, properties: {})
      event_data = {
        Properties::ITEM_ID => item.id,
        Properties::ITEM_NAME => item.name,
        Properties::SHOP_ID => item.shop_id,
        changes: changes
      }.merge(properties)

      track_event(Events::VENDOR_PRODUCT_UPDATED, event_data)
    end

    def track_vendor_order_viewed(order, properties = {})
      event_data = {
        Properties::ORDER_ID => order.id,
        Properties::ORDER_NUMBER => order.number,
        Properties::ORDER_TOTAL => order.total_amount,
        Properties::SHOP_ID => order.shop_id
      }.merge(properties)

      track_event(Events::VENDOR_ORDER_VIEWED, event_data)
    end

    def track_vendor_order_processed(order, new_status:, properties: {})
      event_data = {
        Properties::ORDER_ID => order.id,
        Properties::ORDER_NUMBER => order.number,
        old_status: order.status,
        new_status: new_status,
        Properties::SHOP_ID => order.shop_id
      }.merge(properties)

      track_event(Events::VENDOR_ORDER_PROCESSED, event_data)
    end

    def track_vendor_dashboard_viewed(vendor, properties = {})
      event_data = {
        Properties::VENDOR_ID => vendor.id,
        Properties::SHOP_ID => vendor.shop&.id
      }.merge(properties)

      track_event(Events::VENDOR_DASHBOARD_VIEWED, event_data)
    end

    # --- EMPLOYÉ ---

    def track_employee_shop_accessed(employee, shop, properties = {})
      event_data = {
        employee_id: employee.id,
        employee_role: employee.role,
        Properties::SHOP_ID => shop.id,
        Properties::SHOP_NAME => shop.name
      }.merge(properties)

      track_event(Events::EMPLOYEE_SHOP_ACCESSED, event_data)
    end

    def track_employee_order_managed(employee, order, action:, properties: {})
      event_data = {
        employee_id: employee.id,
        employee_role: employee.role,
        Properties::ORDER_ID => order.id,
        Properties::ORDER_NUMBER => order.number,
        action: action,
        Properties::SHOP_ID => order.shop_id
      }.merge(properties)

      track_event(Events::EMPLOYEE_ORDER_MANAGED, event_data)
    end

    def track_employee_product_managed(employee, item, action:, properties: {})
      event_data = {
        employee_id: employee.id,
        employee_role: employee.role,
        Properties::ITEM_ID => item.id,
        Properties::ITEM_NAME => item.name,
        action: action,
        Properties::SHOP_ID => item.shop_id
      }.merge(properties)

      track_event(Events::EMPLOYEE_PRODUCT_MANAGED, event_data)
    end

    # --- CLIENT ---

    def track_client_profile_updated(user, changes = {}, properties: {})
      event_data = {
        Properties::USER_ID => user.id,
        changes: changes
      }.merge(properties)

      track_event(Events::CLIENT_PROFILE_UPDATED, event_data)
    end

    def track_client_address_added(user, address, properties = {})
      event_data = {
        Properties::USER_ID => user.id,
        address_id: address.id,
        address_type: address.address_type,
        city: address.city,
        country: address.country
      }.merge(properties)

      track_event(Events::CLIENT_ADDRESS_ADDED, event_data)
    end

    def track_client_order_tracked(user, order, properties = {})
      event_data = {
        Properties::USER_ID => user.id,
        Properties::ORDER_ID => order.id,
        Properties::ORDER_NUMBER => order.number,
        order_status: order.status,
        Properties::SHOP_ID => order.shop_id
      }.merge(properties)

      track_event(Events::CLIENT_ORDER_TRACKED, event_data)
    end

    private

    def build_trackers
      trackers = []

      if Analytics.configuration.tracker_enabled?(:ahoy)
        trackers << AhoyTracker.new(user: @user, visit: @visit, controller: @controller)
      end

      if Analytics.configuration.tracker_enabled?(:amplitude)
        trackers << AmplitudeTracker.new(user: @user)
      end

      if Analytics.configuration.tracker_enabled?(:google_analytics)
        trackers << GoogleAnalyticsTracker.new(user: @user)
      end

      trackers
    end

    def build_event_data(event_name, properties)
      {
        event_name: event_name,
        Properties::USER_ID => @user&.id,
        Properties::USER_TYPE => @user&.class&.name,
        Properties::TIMESTAMP => Time.current,
        context: @context
      }.merge(properties)
    end

    def send_to_trackers(event_name, event_data)
      send_start = Time.current
      success_count = 0
      error_count = 0

      trackers.each do |tracker|
        begin
          tracker.track_event(event_name, event_data)
          success_count += 1
        rescue => e
          error_count += 1
          Rails.logger.error("❌ [Analytics::TrackingService] Tracker error (#{tracker.class.name}) - Event: #{event_name} | #{e.class}: #{e.message}")
          Rails.logger.error("❌ [Analytics::TrackingService] Backtrace: #{e.backtrace.first(3).join('\n')}")
        end
      end

      send_duration = (Time.current - send_start).round(3)
      if Analytics.configuration.debug_mode
        Rails.logger.info("📊 [Analytics::TrackingService] Trackers exécutés en #{send_duration}s - Success: #{success_count}/#{trackers.count} | Errors: #{error_count}")
      end
    end
  end
end
