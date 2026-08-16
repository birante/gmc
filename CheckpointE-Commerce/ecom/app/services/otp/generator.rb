# frozen_string_literal: true

module Otp
  # Service centralisé pour générer des codes OTP
  class Generator
    # Génère un code OTP avec la longueur spécifiée
    # @param length [Integer] Longueur du code (défaut: 4)
    # @return [String] Code OTP généré (toujours de la longueur exacte, avec padding de zéros si nécessaire)
    def self.generate(length: 4)
      length = [ length.to_i, 1 ].max # S'assurer que length >= 1

      # Générer un code avec padding de zéros si nécessaire
      # Pour éviter les codes qui commencent par 0 et semblent plus courts
      min_value = 10**(length - 1)
      max_value = 10**length - 1
      rand(min_value..max_value).to_s.rjust(length, "0")
    end

    # Génère un code OTP en utilisant la configuration Rails
    # @param config [ActiveSupport::OrderedOptions] Configuration OTP (ex: Rails.application.config.user_otp)
    # @return [String] Code OTP généré
    def self.generate_from_config(config)
      # IMPORTANT: Utiliser l'accès par hash [:length] car config.length retourne le nombre de clés, pas la valeur
      length = config[:length] || config["length"] || 4
      length = length.to_i if length.respond_to?(:to_i)
      length = [ length.to_i, 1 ].max # S'assurer que length >= 1
      # Force minimum 4 digits pour tous les codes OTP de vérification
      length = [ length, 4 ].max
      generate(length: length)
    end

    # Retourne la durée de validité (TTL) depuis la configuration
    # @param config [ActiveSupport::OrderedOptions] Configuration OTP
    # @return [Integer] TTL en secondes
    def self.ttl_from_config(config)
      # Utiliser l'accès par hash pour éviter les problèmes avec OrderedOptions
      config[:ttl_seconds] || config["ttl_seconds"] || 5.minutes.to_i
    end
  end
end
