module VendorOtpConfiguration
  def vendor_otp
    @_vendor_otp ||= ActiveSupport::OrderedOptions.new
  end

  def vendor_otp=(options)
    @_vendor_otp = options
  end
end

Rails::Application::Configuration.include(VendorOtpConfiguration)

# Configuration centrale pour le flux d'OTP des vendors.
# Utilisé via `Rails.application.config.vendor_otp.length`, `ttl_seconds`, `default_channel`, etc.

# longueur du code OTP (4 digits - TOUS les SMS de vérification doivent être de 4 chiffres)
# Forcé à 4, ignore la variable d'environnement si elle est définie à une autre valeur
Rails.application.config.vendor_otp.length = 4

# durée de validité en secondes (ex : 10 minutes)
Rails.application.config.vendor_otp.ttl_seconds = (ENV["VENDOR_OTP_TTL_SECONDS"] || 10.minutes.to_i).to_i

# canal par défaut (configurable par admin / env). Possible values : "email", "sms"
Rails.application.config.vendor_otp.default_channel = (ENV["VENDOR_OTP_DEFAULT_CHANNEL"] || "email").to_s
