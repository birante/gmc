# frozen_string_literal: true

# Exception levée lors d'erreurs de validation
#
# Usage:
#   raise ValidationError, "Le champ est invalide"
#   raise ValidationError.new("Erreurs de validation", errors: model.errors)
class ValidationError < ApplicationError
  attr_reader :errors

  def initialize(message = "Erreurs de validation", errors: nil, status: :unprocessable_entity)
    super(message, status: status, code: "VALIDATION_ERROR")
    @errors = errors || {}
  end

  # Retourne les erreurs sous forme de tableau de messages
  def error_messages
    return [ message ] if errors.empty?

    if errors.respond_to?(:full_messages)
      errors.full_messages
    elsif errors.is_a?(Hash)
      errors.map { |field, messages| Array(messages).map { |m| "#{field}: #{m}" } }.flatten
    elsif errors.is_a?(Array)
      errors
    else
      [ message ]
    end
  end
end
