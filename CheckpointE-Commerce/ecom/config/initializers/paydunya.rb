# Configuration PayDunya
# Documentation: https://paydunya.com/developers/ruby

# Charger JSON pour compatibilité avec Ruby 3+
require "json"

class PaydunyaConfig
  def self.setup!
    # Configuration des clés d'API
    Paydunya::Setup.master_key = ENV.fetch("PAYDUNYA_MASTER_KEY", "")
    Paydunya::Setup.public_key = ENV.fetch("PAYDUNYA_PUBLIC_KEY", "")
    Paydunya::Setup.private_key = ENV.fetch("PAYDUNYA_PRIVATE_KEY", "")
    Paydunya::Setup.token = ENV.fetch("PAYDUNYA_TOKEN", "")

    # Mode: "test" ou "live"
    Paydunya::Setup.mode = ENV.fetch("PAYDUNYA_MODE", "test")

    # Configuration des informations de votre entreprise
    Paydunya::Checkout::Store.name = ENV.fetch("PAYDUNYA_STORE_NAME", "aa")
    Paydunya::Checkout::Store.tagline = ENV.fetch("PAYDUNYA_STORE_TAGLINE", "Votre marketplace en ligne")
    Paydunya::Checkout::Store.phone_number = ENV.fetch("PAYDUNYA_STORE_PHONE", "")
    Paydunya::Checkout::Store.postal_address = ENV.fetch("PAYDUNYA_STORE_ADDRESS", "Dakar, Sénégal")
    Paydunya::Checkout::Store.website_url = app_url
    Paydunya::Checkout::Store.logo_url = ENV.fetch("PAYDUNYA_STORE_LOGO", "")

    # URLS par défaut pour les paiements de commandes (peuvent être surchargées par transaction)
    # NOTE: Ces URLs sont pour les commandes clients, pas pour les abonnements
    Paydunya::Checkout::Store.cancel_url = "#{app_url}/paydunya/cancel"
    Paydunya::Checkout::Store.return_url = "#{app_url}/paydunya/success"
  end

  def self.callback_urls(locale = "fr")
    base_url = app_url
    # URLs spécifiques pour les abonnements (vendors)
    {
      cancel_url: "#{base_url}/#{locale}/vendors/paydunya/subscription_cancel",
      return_url: "#{base_url}/#{locale}/vendors/paydunya/subscription_success"
    }
  end

  # URL de l'application (détection automatique de l'environnement)
  def self.app_url
    if Rails.env.production?
      ENV.fetch("PAYDUNYA_STORE_URL", "https://aa.okemamy.com")
    elsif Rails.env.staging?
      ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
    else
      ENV.fetch("PAYDUNYA_STORE_URL", "http://localhost:3000")
    end
  end
end

# Appliquer la configuration au démarrage
PaydunyaConfig.setup!
