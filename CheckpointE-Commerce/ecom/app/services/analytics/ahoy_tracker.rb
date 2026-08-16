# frozen_string_literal: true

module Analytics
  class AhoyTracker
    # Clés ajoutées par Analytics::TrackingService#build_event_data qui sont des
    # métadonnées d'événement (déjà persistées dans des colonnes dédiées), à ne
    # pas dupliquer dans la colonne JSON `properties`.
    META_KEYS = %w[event_name user_id user_type timestamp].freeze

    def initialize(user: nil, visit: nil, controller: nil)
      @user = user
      @visit = visit
      @controller = controller
    end

    def track_page_view(page_name, properties = {})
      track_event("page_viewed", properties.merge(page_name: page_name))
    end

    def track_event(event_name, properties = {})
      sanitized = sanitize_properties(properties).stringify_keys
      props = sanitized.except(*META_KEYS)

      if @controller
        @controller.ahoy.track(event_name, props)
      else
        persist_without_request(event_name, props, sanitized)
      end
    rescue => e
      Rails.logger.error("Ahoy tracking error: #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
    end

    private

    # En contexte sans request (job async, console), Ahoy::Tracker#track plante
    # silencieusement sur `request.remote_ip` et l'exception est avalée par
    # `Ahoy.safety`. On insère donc directement dans Ahoy::Event.
    def persist_without_request(event_name, props, sanitized)
      return unless @visit

      time = parse_time(sanitized["timestamp"])
      time = @visit.started_at if @visit.started_at && time < @visit.started_at

      Ahoy::Event.create!(
        visit_id: @visit.id,
        user_id: @user&.id || sanitized["user_id"],
        user_type: @user&.class&.name || sanitized["user_type"],
        name: event_name,
        properties: props,
        time: time,
        shop_id: props["shop_id"].presence,
        item_id: props["item_id"].presence
      )
    rescue ActiveRecord::RecordNotUnique
      # Idempotence si l'événement a déjà été persisté (retry de job)
    end

    def parse_time(value)
      return Time.current if value.blank?

      case value
      when Time, DateTime, ActiveSupport::TimeWithZone then value
      when String then Time.zone.parse(value) || Time.current
      else Time.current
      end
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
        else
          value
        end
      end
    end
  end
end
