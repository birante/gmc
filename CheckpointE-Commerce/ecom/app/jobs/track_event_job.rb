# frozen_string_literal: true

class TrackEventJob < ApplicationJob
  queue_as :default

  # visit_id est passé optionnellement pour que Ahoy puisse rattacher l'événement
  # à la visite d'origine (le tracker en background n'a pas de request context).
  def perform(event_name, event_data, visit_id: nil)
    trackers = build_trackers(visit_id: visit_id)

    trackers.each do |tracker|
      tracker.track_event(event_name, event_data)
    rescue => e
      Rails.logger.error("Async tracking error (#{tracker.class.name}): #{e.message}")
    end
  end

  private

  def build_trackers(visit_id: nil)
    trackers = []

    if Analytics.configuration.tracker_enabled?(:ahoy)
      visit = visit_id ? Ahoy::Visit.find_by(id: visit_id) : nil
      trackers << Analytics::AhoyTracker.new(visit: visit)
    end

    if Analytics.configuration.tracker_enabled?(:amplitude)
      trackers << Analytics::AmplitudeTracker.new
    end

    if Analytics.configuration.tracker_enabled?(:google_analytics)
      trackers << Analytics::GoogleAnalyticsTracker.new
    end

    trackers
  end
end
