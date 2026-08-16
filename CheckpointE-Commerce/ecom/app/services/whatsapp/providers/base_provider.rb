# frozen_string_literal: true

module Whatsapp
  module Providers
    # Interface de base pour tous les providers WhatsApp
    class BaseProvider
      class NotImplementedError < StandardError; end

      # Envoie un message WhatsApp
      # @param to [String] Numéro de téléphone du destinataire (format international sans +)
      # @param message [String] Contenu du message
      # @param template_name [String] Nom du template (optionnel, pour messages template)
      # @param template_params [Array] Paramètres du template (optionnel)
      # @return [Hash] Résultat de l'envoi avec :success, :message, :provider_response
      def send(to:, message:, template_name: nil, template_params: [])
        raise NotImplementedError, "#{self.class} doit implémenter la méthode #send"
      end

      # Vérifie les crédits/disponibilité
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
