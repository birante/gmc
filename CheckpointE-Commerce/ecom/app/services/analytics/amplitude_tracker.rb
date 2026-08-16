# frozen_string_literal: true

require "httparty"

module Analytics
  class AmplitudeTracker
    include HTTParty
    base_uri "https://api2.amplitude.com"

    BATCH_API_ENDPOINT = "/2/httpapi"
    MAX_BATCH_SIZE = 10

    def initialize(user: nil, **_options)
      @user = user
      @events_queue = []
    end

    def track_page_view(page_name, properties = {})
      track_event("Page Viewed", properties.merge(page_name: page_name))
    end

    def track_event(event_name, properties = {})
      return unless enabled?

      event_data = build_event_data(event_name, properties)

      # Envoi direct ou batch selon la configuration
      if Rails.env.production?
        queue_event(event_data)
      else
        send_event(event_data)
      end

      Rails.logger.debug("Amplitude tracking: #{event_name} - #{properties.inspect}") if Rails.env.development?
    rescue => e
      Rails.logger.error("Amplitude tracking error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
    end

    def flush
      return if @events_queue.empty?

      send_batch(@events_queue)
      @events_queue.clear
    end

    private

    def enabled?
      api_key.present?
    end

    def api_key
      ENV["AMPLITUDE_API_KEY"]
    end

    def user_identifier
      @user&.id&.to_s || "anonymous_#{SecureRandom.uuid}"
    end

    def build_event_data(event_name, properties)
      {
        user_id: user_identifier,
        event_type: event_name,
        event_properties: sanitize_properties(properties),
        time: (Time.current.to_f * 1000).to_i, # Milliseconds
        platform: "Web",
        user_properties: user_properties,
        app_version: "1.0.0"
      }
    end

    def user_properties
      return {} unless @user

      props = {}

      # Type d'utilisateur (User, Vendor, Employee)
      user_type = @user.class.name
      props[:user_type] = user_type

      # Email
      if @user.respond_to?(:email) && @user.email.present?
        props[:email] = @user.email
      end

      # Date de création
      if @user.respond_to?(:created_at)
        props[:user_created_at] = @user.created_at.iso8601
      end

      # Propriétés spécifiques selon le type
      case user_type
      when "User"
        # Propriétés du client
        props[:user_role] = "client"
        props[:is_premium] = @user.respond_to?(:premium?) ? @user.premium? : false

        if @user.respond_to?(:orders)
          props[:total_orders] = @user.orders.count
          props[:lifetime_value] = @user.orders.sum(:total_amount).to_f
        end

      when "Vendor"
        # Propriétés du vendeur
        props[:user_role] = "vendor"
        props[:vendor_status] = @user.status if @user.respond_to?(:status)

        if @user.respond_to?(:shop)
          props[:has_shop] = @user.shop.present?
          props[:shop_id] = @user.shop&.id
          props[:shop_name] = @user.shop&.name
          props[:shop_status] = @user.shop&.status
        end

        if @user.respond_to?(:items)
          props[:total_products] = @user.items.count rescue 0
        end

      when "Employee"
        # Propriétés de l'employé
        props[:user_role] = "employee"
        props[:employee_role] = @user.role if @user.respond_to?(:role)

        if @user.respond_to?(:shops)
          props[:shops_count] = @user.shops.count
          props[:shop_ids] = @user.shops.pluck(:id)
        end
      end

      props
    end

    def sanitize_properties(properties)
      properties.transform_values do |value|
        case value
        when ActiveRecord::Base
          value.id
        when Time, DateTime, ActiveSupport::TimeWithZone
          value.iso8601
        when BigDecimal
          value.to_f
        when Hash
          sanitize_properties(value) # Récursif pour les hash imbriqués
        when Array
          value.map { |v| sanitize_properties({ v: v })[:v] }
        else
          value
        end
      end
    end

    def send_event(event_data)
      send_batch([ event_data ])
    end

    def send_batch(events)
      return if events.empty?

      response = self.class.post(
        BATCH_API_ENDPOINT,
        body: {
          api_key: api_key,
          events: events
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        },
        timeout: 5
      )

      if response.success?
        Rails.logger.debug("Amplitude: Successfully sent #{events.size} event(s)") if Rails.env.development?
      else
        Rails.logger.error("Amplitude API error: #{response.code} - #{response.body}")
      end
    rescue => e
      Rails.logger.error("Amplitude HTTP error: #{e.message}")
    end

    def queue_event(event_data)
      @events_queue << event_data

      # Flush automatique si le batch est plein
      flush if @events_queue.size >= MAX_BATCH_SIZE
    end
  end
end
