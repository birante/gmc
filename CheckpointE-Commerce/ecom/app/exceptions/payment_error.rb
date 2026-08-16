# frozen_string_literal: true

# Exception levée lors d'erreurs de paiement
#
# Usage:
#   raise PaymentError, "Échec du paiement"
#   raise PaymentError.new("Paiement refusé", provider: "PayDunya")
class PaymentError < ApplicationError
  attr_reader :provider

  def initialize(message = "Erreur de paiement", provider: nil, status: :payment_required)
    super(message, status: status, code: "PAYMENT_ERROR")
    @provider = provider
  end
end
