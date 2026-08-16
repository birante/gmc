# frozen_string_literal: true

module UserOtpConfiguration
  def user_otp
    @_user_otp ||= ActiveSupport::OrderedOptions.new
  end

  def user_otp=(options)
    @_user_otp = options
  end
end

Rails::Application::Configuration.include(UserOtpConfiguration)

# Configuration centrale pour le flux d'OTP des users (clients).
# Utilisé via `Rails.application.config.user_otp.length`, `ttl_seconds`, `default_channel`, etc.

# longueur du code OTP (4 digits - TOUS les SMS de vérification doivent être de 4 chiffres)
# Forcé à 4, ignore la variable d'environnement si elle est définie à une autre valeur
# IMPORTANT: Cette valeur DOIT être définie APRÈS le chargement des variables d'environnement
Rails.application.config.user_otp.length = 4
# Forcer explicitement la valeur à 4, même si une variable d'environnement essaie de la modifier
Rails.application.config.user_otp.length = 4 if Rails.application.config.user_otp.length != 4

# durée de validité en secondes (ex : 5 minutes)
Rails.application.config.user_otp.ttl_seconds = (ENV["USER_OTP_TTL_SECONDS"] || 5.minutes.to_i).to_i

# canal par défaut (configurable par admin / env). Possible values : "email", "sms"
Rails.application.config.user_otp.default_channel = (ENV["USER_OTP_DEFAULT_CHANNEL"] || "sms").to_s
