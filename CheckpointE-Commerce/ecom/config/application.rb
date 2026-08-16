require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module aaapps
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # load_defaults active des jetons CSRF liés au path du formulaire (depuis la chaîne 5.x).
    # En production derrière un proxy / plusieurs hôtes, cela peut provoquer des 422
    # alors que le cookie de session est valide. La protection CSRF globale reste active.
    config.action_controller.per_form_csrf_tokens = false

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Internationalization
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [ :fr, :en ]
    config.i18n.fallbacks = true
    # Charger les traductions depuis les sous-répertoires
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

    # Configure acronyms for autoloading
    config.active_support.acronyms = { "AI" => "AI" }
  end
end
