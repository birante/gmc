# frozen_string_literal: true

# Exception levée lors d'erreurs dans les repositories
#
# Usage:
#   raise RepositoryError, "Erreur lors de la création"
#   raise RepositoryError.new("Impossible de sauvegarder", model: model)
class RepositoryError < ApplicationError
  attr_reader :model

  def initialize(message = "Erreur de repository", model: nil, status: :internal_server_error)
    super(message, status: status, code: "REPOSITORY_ERROR")
    @model = model
  end
end
