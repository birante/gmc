# frozen_string_literal: true

# Configuration des providers SMS
#
# Variables d'environnement requises:
# - SEND_SMS_ENABLED: "true" pour activer l'envoi de SMS (défaut: "false")
# - SMS_PROVIDER: Nom du provider à utiliser (défaut: "lam_service")
#
# Providers disponibles:
# - lam_service: Provider LAM (configuré via variables LAM_*)
#
# Exemple d'utilisation:
#   Sms::SmsService.new.send_sms(
#     to: "221776857298",
#     message: "Votre code de vérification: 12345",
#     sms_type: "verification"
#   )

# TODO: Activer l'envoi de SMS par défaut une fois les providers SMS configurés
Rails.application.config.sms_providers = {
  enabled: ENV.fetch("SEND_SMS_ENABLED", "true") == "true",
  default_provider: ENV.fetch("SMS_PROVIDER", "lam_service")
}
