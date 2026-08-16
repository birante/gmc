# frozen_string_literal: true

# Service de normalisation des numéros de téléphone pour différents pays
# Convertit les formats variés en numéro E.164 international standard
#
# Usage:
#   PhoneNormalizerService.normalize("776857298", country_code: "SN")
#   => "+221776857298"
#
#   PhoneNormalizerService.normalize("0776857298", country_code: "SN")
#   => "+221776857298"
#
#   PhoneNormalizerService.normalize("+221776857298")
#   => "+221776857298"
#
class PhoneNormalizerService
  # Codes pays par pays (ISO 3166-1 alpha-2)
  COUNTRY_CODES = {
    "SN" => "221",  # Sénégal
    "CI" => "225",  # Côte d'Ivoire
    "ML" => "223",  # Mali
    "BJ" => "229",  # Bénin
    "BF" => "226",  # Burkina Faso
    "TG" => "228",  # Togo
    "NE" => "227",  # Niger
    "GM" => "220",  # Gambia
    "GW" => "245",  # Guinea-Bissau
    "GN" => "224",  # Guinea
    "LR" => "231",  # Liberia
    "SL" => "232",  # Sierra Leone
    "CM" => "237",  # Cameroun
    "GA" => "241",  # Gabon
    "CD" => "243",  # Congo RDC
    "CG" => "242",  # Congo
    "TD" => "235",  # Chad
    "CF" => "236",  # Central African Republic
    "KE" => "254",  # Kenya
    "UG" => "256",  # Uganda
    "TZ" => "255",  # Tanzania
    "RW" => "250",  # Rwanda
    "ZA" => "27",   # South Africa
    "NG" => "234",  # Nigeria
    "GH" => "233",  # Ghana
    "MA" => "212",  # Morocco
    "DZ" => "213",  # Algeria
    "TN" => "216",  # Tunisia
    "EG" => "20"   # Egypt
  }.freeze

  def self.normalize(phone_number, country_code: "SN")
    new(phone_number, country_code).call
  end

  def initialize(phone_number, country_code = "SN")
    @phone_number = phone_number.to_s.strip
    @country_code = country_code.upcase
  end

  def call
    return nil if @phone_number.blank?

    # Étape 1 : Supprimer les caractères non-numériques sauf le +
    cleaned = @phone_number.gsub(/[^\d+]/, "")
    return nil if cleaned.blank?

    # Étape 2 : Si commence par +, c'est déjà au format international
    return cleaned if cleaned.start_with?("+")

    # Étape 3 : Si commence par 00, remplacer par +
    if cleaned.start_with?("00")
      return "+" + cleaned[2..]
    end

    # Étape 4 : Ajouter le code pays
    dial_code = COUNTRY_CODES[@country_code]
    return nil unless dial_code.present?

    # Format: +[country_code][number]
    "+#{dial_code}#{cleaned}"
  end

  # Retourner juste les digits (pour LAM)
  def to_lam_format
    normalized = call
    return nil unless normalized.present?

    # Supprimer le + pour LAM qui n'aime que les digits
    normalized.gsub(/^\+/, "")
  end

  # Valider si le numéro semble valide (longueur d'onde)
  def valid?
    normalized = call
    return false unless normalized.present?

    # Format: +[country_code][local_number]
    # Longueur typique : 11-15 chiffres
    digits = normalized.gsub(/\D/, "")
    digits.length >= 11 && digits.length <= 15
  end
end
