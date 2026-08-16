# frozen_string_literal: true

module Sms
  class MessageValidator
    # Limites SMS standard
    SMS_MAX_LENGTH_GSM7 = 160 # Caractères GSM-7 (latin basique)
    SMS_SEGMENT_LENGTH_GSM7 = 153 # Longueur par segment pour GSM-7
    SMS_MAX_LENGTH_UNICODE = 70 # Caractères Unicode (UTF-16)
    SMS_SEGMENT_LENGTH_UNICODE = 67 # Longueur par segment pour Unicode

    class MessageTooLongError < StandardError; end

    # Vérifie si le message contient des caractères Unicode
    # @param message [String] Le message à vérifier
    # @return [Boolean] true si le message contient des caractères Unicode
    def self.unicode?(message)
      # Vérifier si le message contient des caractères hors du jeu GSM-7
      # Le jeu GSM-7 inclut les caractères ASCII de base + quelques caractères étendus
      # Pour simplifier, on vérifie si le message peut être encodé en GSM-7
      # ou s'il contient des caractères spéciaux (emojis, accents complexes, etc.)

      # Caractères GSM-7 de base (simplifié)
      gsm7_basic = /^[A-Za-z0-9\s@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ!"#¤%&'()*+,\-.\/:;<=>?¡ÄÖÑÜ§¿äöñüà]*$/

      # Si le message ne correspond pas au pattern GSM-7, c'est probablement Unicode
      !message.match?(gsm7_basic) || message.bytesize > message.length
    end

    # Calcule le nombre de segments SMS nécessaires
    # @param message [String] Le message à analyser
    # @return [Hash] Informations sur la segmentation
    def self.calculate_segments(message)
      return { segments: 0, encoding: nil, total_length: 0 } if message.nil? || message.empty?

      is_unicode = unicode?(message)
      max_length = is_unicode ? SMS_MAX_LENGTH_UNICODE : SMS_MAX_LENGTH_GSM7
      segment_length = is_unicode ? SMS_SEGMENT_LENGTH_UNICODE : SMS_SEGMENT_LENGTH_GSM7

      message_length = message.length
      segments = if message_length <= max_length
        1
      else
        (message_length.to_f / segment_length).ceil
      end

      {
        segments: segments,
        encoding: is_unicode ? "unicode" : "gsm7",
        total_length: message_length,
        max_length: max_length,
        segment_length: segment_length,
        cost_multiplier: segments # Chaque segment coûte un SMS
      }
    end

    # Valide la longueur du message et lève une exception si trop long
    # @param message [String] Le message à valider
    # @param max_segments [Integer] Nombre maximum de segments autorisés (défaut: 3)
    # @raise [MessageTooLongError] Si le message dépasse la limite
    def self.validate!(message, max_segments: 3)
      return if message.nil? || message.empty?

      info = calculate_segments(message)

      if info[:segments] > max_segments
        raise MessageTooLongError,
          "Le message SMS est trop long (#{info[:total_length]} caractères, #{info[:segments]} segments). " \
          "Maximum autorisé: #{max_segments} segments (#{max_segments * info[:segment_length]} caractères). " \
          "Encodage: #{info[:encoding]}"
      end

      info
    end

    # Valide la longueur du message et retourne un warning si trop long
    # @param message [String] Le message à valider
    # @param max_segments [Integer] Nombre maximum de segments autorisés (défaut: 3)
    # @return [Hash] Informations de validation avec warning si nécessaire
    def self.validate(message, max_segments: 3)
      return { valid: true, info: nil } if message.nil? || message.empty?

      info = calculate_segments(message)
      valid = info[:segments] <= max_segments

      warning = if !valid
        "⚠️ Message SMS long: #{info[:total_length]} caractères, #{info[:segments]} segments " \
        "(coût: #{info[:cost_multiplier]}x SMS). Encodage: #{info[:encoding]}"
      elsif info[:segments] > 1
        "ℹ️ Message SMS segmenté: #{info[:segments]} segments (#{info[:total_length]} caractères). " \
        "Encodage: #{info[:encoding]}"
      end

      {
        valid: valid,
        info: info,
        warning: warning
      }
    end
  end
end
