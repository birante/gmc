# Configuration des retries pour ActionMailer::MailDeliveryJob
# Cela permet de réessayer automatiquement l'envoi d'emails en cas d'erreur de timeout ou de connexion

# Redéfinir le job de livraison d'email pour ajouter des retries
module ActionMailer
  class MailDeliveryJob < ActiveJob::Base
    # Retry sur les erreurs de timeout et de connexion réseau
    retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 3
    retry_on Net::ReadTimeout, wait: :exponentially_longer, attempts: 3
    retry_on Net::SMTPError, wait: :exponentially_longer, attempts: 3
    retry_on SocketError, wait: :exponentially_longer, attempts: 3
    retry_on Errno::ECONNREFUSED, wait: :exponentially_longer, attempts: 3
    retry_on Errno::ETIMEDOUT, wait: :exponentially_longer, attempts: 3

    # Logger les erreurs mais ne pas bloquer l'application
    discard_on ActiveJob::DeserializationError do |job, error|
      Rails.logger.error "❌ [ActionMailer::MailDeliveryJob] Erreur de désérialisation: #{error.message}"
    end

    # Logger les erreurs après tous les retries échoués
    after_discard do |job, error|
      Rails.logger.error "❌ [ActionMailer::MailDeliveryJob] Échec définitif après tous les retries: #{error.class} - #{error.message}"
    end
  end
end
