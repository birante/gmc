# frozen_string_literal: true

module Sms
  module Providers
    # Interface de base pour tous les providers SMS
    # Chaque provider doit implémenter les méthodes suivantes:
    # - send(to:, message:) -> Envoie un SMS
    # - credits -> Retourne les crédits disponibles (optionnel)
    class BaseProvider
      class NotImplementedError < StandardError; end

      # Envoie un SMS
      # @param to [String] Numéro de téléphone du destinataire
      # @param message [String] Contenu du message
      # @return [Hash] Résultat de l'envoi avec :success, :message, :provider_response
      def send(to:, message:)
        raise NotImplementedError, "#{self.class} doit implémenter la méthode #send"
      end

      # Vérifie les crédits disponibles
      # @return [Hash] Informations sur les crédits avec :success, :balance, :currency
      def credits
        raise NotImplementedError, "#{self.class} doit implémenter la méthode #credits"
      end

      # Nom du provider (utilisé pour le logging)
      def provider_name
        self.class.name.demodulize
      end
    end
  end
end
