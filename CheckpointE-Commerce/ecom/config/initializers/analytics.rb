# frozen_string_literal: true

module Analytics
  class Configuration
    attr_accessor :enabled, :trackers, :debug_mode, :async_tracking

    def initialize
      @enabled = true
      @trackers = {
        ahoy: true,
        amplitude: false,
        google_analytics: false,
        facebook_pixel: false
      }
      @debug_mode = Rails.env.development?
      @async_tracking = Rails.env.production?
    end

    def tracker_enabled?(tracker_name)
      enabled && trackers[tracker_name]
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def enabled?
      configuration.enabled
    end
  end
end

# Configuration par défaut
Analytics.configure do |config|
  # Activer/désactiver tout le système de tracking
  config.enabled = ENV.fetch("ANALYTICS_ENABLED", "true") == "true"

  # Activer les trackers selon les variables d'environnement
  # Ahoy: Toujours actif par défaut (first-party analytics)
  config.trackers[:ahoy] = ENV.fetch("AHOY_ENABLED", "true") == "true"

  # Amplitude: Désactivé par défaut, activer via AMPLITUDE_ENABLED=true
  config.trackers[:amplitude] = ENV.fetch("AMPLITUDE_ENABLED", "false") == "true" &&
                                 ENV["AMPLITUDE_API_KEY"].present?

  # Google Analytics: Désactivé par défaut, activer via GA_ENABLED=true
  config.trackers[:google_analytics] = ENV.fetch("GA_ENABLED", "false") == "true" &&
                                        ENV["GA_MEASUREMENT_ID"].present?

  # Facebook Pixel: Activé par défaut (ID hardcodé en fallback), désactiver via FB_PIXEL_ENABLED=false
  config.trackers[:facebook_pixel] = ENV.fetch("FB_PIXEL_ENABLED", "true") == "true"

  # Mode debug en développement
  config.debug_mode = Rails.env.development?

  # Tracking asynchrone en production
  config.async_tracking = Rails.env.production?

  # Logger la configuration au démarrage
  if Rails.env.development?
    Rails.logger.info("📊 Analytics Configuration:")
    Rails.logger.info("  - System enabled: #{config.enabled}")
    Rails.logger.info("  - Ahoy: #{config.trackers[:ahoy] ? '✅' : '❌'}")
    Rails.logger.info("  - Amplitude: #{config.trackers[:amplitude] ? '✅' : '❌'}")
    Rails.logger.info("  - Google Analytics: #{config.trackers[:google_analytics] ? '✅' : '❌'}")
    Rails.logger.info("  - Facebook Pixel: #{config.trackers[:facebook_pixel] ? '✅' : '❌'}")
  end
end
