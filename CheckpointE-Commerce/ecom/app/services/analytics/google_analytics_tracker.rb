# frozen_string_literal: true

module Analytics
  class GoogleAnalyticsTracker
    def initialize(user: nil, **_options)
      @user = user
    end

    def track_page_view(page_name, properties = {})
      track_event("page_view", properties.merge(page_title: page_name))
    end

    def track_event(event_name, properties = {})
      return unless enabled?

      # Google Analytics sera principalement géré côté client via gtag.js
      # Pour le server-side tracking, on peut utiliser Measurement Protocol API
      # https://developers.google.com/analytics/devguides/collection/protocol/ga4

      Rails.logger.debug("Google Analytics tracking: #{event_name} - #{properties.inspect}") if Rails.env.development?
    rescue => e
      Rails.logger.error("Google Analytics tracking error: #{e.message}")
    end

    private

    def enabled?
      ENV["GA_MEASUREMENT_ID"].present?
    end
  end
end
