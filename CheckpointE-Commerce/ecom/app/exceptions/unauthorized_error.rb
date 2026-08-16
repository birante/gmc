# frozen_string_literal: true

# Exception levée lors d'erreurs d'autorisation
#
# Usage:
#   raise UnauthorizedError, "Accès refusé"
#   raise UnauthorizedError.new("Vous n'avez pas les droits nécessaires")
class UnauthorizedError < ApplicationError
  def initialize(message = "Accès refusé", status: :forbidden)
    super(message, status: status, code: "UNAUTHORIZED")
  end
end
