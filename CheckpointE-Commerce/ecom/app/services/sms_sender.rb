# Service d'envoi de SMS (DÉPRÉCIÉ)
#
# @deprecated Utilisez Sms::SmsService à la place pour l'envoi de SMS en production.
#   Ce service est conservé uniquement pour compatibilité avec l'ancien code.
#
# ATTENTION: Ce service ne fait que logger, il n'envoie PAS de SMS réel !
#
# Migration recommandée:
#   Ancien: SmsSender.send_sms("221776857298", "Message")
#   Nouveau: Sms::SmsService.new.send_sms(to: "221776857298", message: "Message", sms_type: "notification")
#
# @see Sms::SmsService
class SmsSender
  def self.send_sms(phone_number, text)
    # Remplacer par intégration Twilio/ autre en production.
    Rails.logger.info("📱 [SmsSender] Envoi SMS à #{phone_number}: #{text}")
    true
  rescue => e
    Rails.logger.error("❌ [SmsSender] Erreur envoi SMS: #{e.message}")
    false
  end
end
