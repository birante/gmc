# Service de validation et formatage des numéros de téléphone
#
# Utilise la gem phonelib pour valider les numéros selon les standards internationaux.
# Supporte plusieurs pays avec fallback sur validation basique si phonelib échoue.
#
# Usage:
#   service = PhoneValidationService.new("776857298", "221")
#   if service.valid?
#     formatted = service.formatted_number # => "+221776857298"
#   end
#
#   # Formatage direct
#   PhoneValidationService.formatted_number("776857298", "221") # => "+221776857298"
#
# Pays supportés:
#   - 221: Sénégal
#   - 225: Côte d'Ivoire
#   - 237: Cameroun
#   - 243: RD Congo
#
class PhoneValidationService
  def initialize(phone_number, country_code)
    @phone_number = normalize_phone_number(phone_number)
    @country_code = normalize_country_code(country_code)
  end

  def valid?
    return false if @phone_number.blank? || @country_code.blank?

    # Essayer d'utiliser Phonelib en priorité
    begin
      phone = Phonelib.parse(@phone_number, iso_country_code)
      phone.valid? && (phone.type == :mobile || phone.type == :fixed_or_mobile)
    rescue => e
      Rails.logger.warn("⚠️ [PhoneValidationService] Phonelib validation failed: #{e.message}, falling back to basic validation")
      # Fallback sur validation basique
      basic_validation
    end
  end

  def formatted_number
    return nil if @phone_number.blank? || @country_code.blank?

    # Essayer d'utiliser Phonelib pour le formatage
    begin
      phone = Phonelib.parse(@phone_number, iso_country_code)
      phone.full_e164 if phone.valid?
    rescue => e
      Rails.logger.warn("⚠️ [PhoneValidationService] Phonelib formatting failed: #{e.message}, falling back to basic formatting")
      # Fallback sur formatage basique
      basic_formatting
    end
  end

  def error_message
    return "Le numéro de téléphone est requis" if @phone_number.blank?
    return "Le code pays est requis" if @country_code.blank?
    return "n'est pas un numéro de téléphone mobile valide" unless valid?
    nil
  end

  private

  def normalize_phone_number(phone_number)
    case phone_number
    when String
      phone_number.strip.gsub(/\D/, "")
    when Hash
      phone_number.values.first.to_s.strip.gsub(/\D/, "")
    else
      phone_number.to_s.strip.gsub(/\D/, "")
    end
  end

  def normalize_country_code(country_code)
    normalized = case country_code
    when String
      country_code.strip
    when Hash
      country_code.values.first.to_s.strip
    else
      country_code.to_s.strip
    end

    # Retirer le préfixe + si présent
    normalized.gsub(/^\+/, "")
  end

  # Convertir le code pays en format ISO2 pour Phonelib
  def iso_country_code
    # Mapping des codes téléphoniques vers les codes ISO2
    country_mapping = {
      "221" => "SN", # Senegal
      "33" => "FR",  # France
      "1" => "US",    # United States
      "44" => "GB",   # United Kingdom
      "212" => "MA",  # Morocco
      "225" => "CI",  # Côte d'Ivoire
      "223" => "ML",  # Mali
      "226" => "BF"   # Burkina Faso
    }

    # Si c'est déjà un code ISO2 (2 lettres), le retourner tel quel
    return @country_code.upcase if @country_code.length == 2 && @country_code.match?(/[A-Za-z]{2}/)

    # Sinon, chercher dans le mapping
    country_mapping[@country_code] || @country_code.upcase
  end

  def self.valid?(phone_number, country_code)
    new(phone_number, country_code).valid?
  end

  def self.formatted_number(phone_number, country_code)
    new(phone_number, country_code).formatted_number
  end

  def basic_validation
    case @country_code
    when "221", "SN" # Senegal
      @phone_number.match?(/\A7[0-9]{8}\z/) # Format sénégalais: 7XXXXXXXX
    when "33", "FR" # France
      @phone_number.match?(/\A[0-9]{9}\z/)
    else
      @phone_number.match?(/\A[0-9]{8,15}\z/) # Format international basique
    end
  end

  def basic_formatting
    case @country_code
    when "221", "SN" # Senegal
      "+221#{@phone_number}" if basic_validation
    when "33", "FR" # France
      "+33#{@phone_number}" if basic_validation
    else
      "+#{@country_code}#{@phone_number}" if basic_validation
    end
  end
end
