# frozen_string_literal: true

# Exception levée lorsqu'une ressource n'est pas trouvée
#
# Usage:
#   raise NotFoundError, "Commande introuvable"
#   raise NotFoundError.new("Order", id: order_id)
class NotFoundError < ApplicationError
  def initialize(resource = "Ressource", id: nil, status: :not_found)
    message = id ? "#{resource} avec l'ID #{id} n'a pas été trouvé(e)" : "#{resource} n'a pas été trouvé(e)"
    super(message, status: status, code: "NOT_FOUND")
    @resource = resource
    @id = id
  end
end
