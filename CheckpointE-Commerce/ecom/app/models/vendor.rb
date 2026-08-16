class Vendor < ApplicationRecord
  has_secure_password

  has_many :sessions, as: :sessionable, dependent: :destroy
  has_many :shops, dependent: :destroy
  has_many :vendor_verifications, dependent: :delete_all
  has_many :employees, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :phone_number, with: ->(p) { p.to_s.strip.gsub(/\D/, "") }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone_number, presence: true, uniqueness: true
  validates :country_code, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  validate :phone_number_format

  # Enum pour le statut
  enum :status, {
    pending: "pending",
    active: "active",
    suspended: "suspended",
    inactive: "inactive"
  }, default: :pending

  # Callbacks pour logging
  after_create :log_creation
  after_update :log_update, if: :saved_changes?

  private

  def log_creation
    Rails.logger.info("🏪 [Vendor] Vendeur créé - vendor_id: #{id}, email: #{email}, téléphone: #{phone_number}, nom: #{first_name} #{last_name}")
  end

  def log_update
    changes_summary = saved_changes.except("updated_at", "password_digest").keys.join(", ")
    Rails.logger.info("✏️ [Vendor] Vendeur mis à jour - vendor_id: #{id}, champs modifiés: #{changes_summary}") if changes_summary.present?
  end

  def phone_number_format
    return if phone_number.blank? || country_code.blank?

    service = PhoneValidationService.new(phone_number, country_code)
    unless service.valid?
      error_msg = service.error_message
      errors.add(:phone_number, error_msg) if error_msg
    end
  end

  public

  # Méthode pour valider le numéro de téléphone selon le pays
  def phone_number_valid?
    PhoneValidationService.valid?(phone_number, country_code)
  end

  # Méthode pour formater le numéro de téléphone
  def formatted_phone_number
    PhoneValidationService.formatted_number(phone_number, country_code)
  end

  # Méthode pour obtenir le nom complet
  def full_name
    "#{first_name} #{last_name}"
  end

  # Relation avec la vérification (une seule vérification active)
  def vendor_verification
    vendor_verifications.last
  end

  # Vérifie si le compte vendor a été vérifié
  # Un compte est considéré comme vérifié s'il a au moins une vérification utilisée (status = true)
  # ET que le statut du vendor est 'active'
  def verified?
    status == "active" && vendor_verifications.exists?(status: true)
  end

  # Retourne la dernière vérification utilisée
  def last_verification
    vendor_verifications.where(status: true).order(used_at: :desc).first
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email", "first_name", "id", "last_name", "phone_number", "country_code", "updated_at", "status" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "shops" ]
  end
end
