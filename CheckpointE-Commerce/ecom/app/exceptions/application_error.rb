# frozen_string_literal: true

# Classe de base pour toutes les exceptions de l'application
#
# Usage:
#   raise ApplicationError, "Message d'erreur"
#   raise ApplicationError.new("Message d'erreur", status: :bad_request)
class ApplicationError < StandardError
  attr_reader :status, :code

  def initialize(message = nil, status: :internal_server_error, code: nil)
    super(message)
    @status = status
    @code = code
  end

  # Méthode pour logger l'erreur
  def log(context = {})
    Rails.logger.error("[#{self.class.name}] #{message}")
    Rails.logger.error("  Status: #{status}, Code: #{code}")
    Rails.logger.error("  Context: #{context.inspect}") if context.present?
  end
end
