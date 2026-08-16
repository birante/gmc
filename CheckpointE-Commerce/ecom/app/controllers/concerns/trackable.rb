# frozen_string_literal: true

module Trackable
  extend ActiveSupport::Concern
  include Analytics::EventDefinitions

  included do
    before_action :setup_analytics_tracker
    after_action :track_page_view_automatically, if: :should_track_page?
  end

  private

  def current_visit
    @current_visit ||= ahoy.visit if respond_to?(:ahoy)
  end

  def analytics
    @analytics ||= Analytics::TrackingService.new(
      user: current_user || current_vendor,
      visit: current_visit,
      context: analytics_context,
      controller: self
    )
  end

  def setup_analytics_tracker
    # Configure le tracker pour cette requête
    # Peut être utilisé pour des configurations spécifiques
  end

  def track_page_view_automatically
    analytics.track_page_view(
      analytics_page_name,
      {
        Properties::PAGE_URL => request.url,
        Properties::PAGE_REFERRER => request.referrer,
        controller: controller_path,
        action: action_name
      }
    )
  end

  def should_track_page?
    # Ne pas tracker les requêtes AJAX, Turbo, JSON, etc.
    !request.xhr? &&
      request.format.html? &&
      !request.headers["Turbo-Frame"]
  end

  def analytics_page_name
    # Utiliser le mapping des constantes
    Analytics::EventDefinitions.page_name_for(controller_path, action_name)
  end

  def analytics_context
    {
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
      Properties::LOCALE => I18n.locale,
      Properties::UTM_SOURCE => params[:utm_source],
      Properties::UTM_MEDIUM => params[:utm_medium],
      Properties::UTM_CAMPAIGN => params[:utm_campaign],
      Properties::SOURCE => params[:source],
      Properties::MEDIUM => params[:medium],
      Properties::CAMPAIGN => params[:campaign]
    }.compact
  end

  # Helper pour tracker facilement dans les actions
  def track_event(event_name, properties = {})
    analytics.track_event(event_name, properties)
  end
end
