# frozen_string_literal: true

class MaintenanceNotification < ApplicationRecord
  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :phone_number, with: ->(p) { p.to_s.strip.gsub(/\D/, "") }

  # Enum pour le type d'utilisateur
  enum :user_type, {
    particulier: "particulier",
    proprietaire_boutique: "proprietaire_boutique"
  }, default: :particulier

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone_number, presence: true
  validates :country_code, presence: true
  validates :user_type, presence: true

  # Validation personnalisée pour le numéro de téléphone
  validate :phone_number_format

  scope :notified, -> { where.not(notified_at: nil) }
  scope :pending, -> { where(notified_at: nil) }
  scope :particuliers, -> { where(user_type: :particulier) }
  scope :proprietaires_boutique, -> { where(user_type: :proprietaire_boutique) }

  def self.ransackable_attributes(auth_object = nil)
    [ "country_code", "created_at", "email", "first_name", "id", "last_name", "notified_at", "phone_number", "updated_at", "user_type" ]
  end

  # Callbacks pour logging
  after_create :log_creation

  def user_type_label
    case user_type
    when "particulier"
      "Particulier"
    when "proprietaire_boutique"
      "Propriétaire de boutique"
    else
      user_type.humanize
    end
  end

  # Méthode pour obtenir le nom complet
  def full_name
    "#{first_name} #{last_name}"
  end

  # Méthode pour valider le numéro de téléphone selon le pays
  def phone_number_valid?
    PhoneValidationService.valid?(phone_number, country_code)
  end

  # Méthode pour formater le numéro de téléphone
  def formatted_phone_number
    PhoneValidationService.formatted_number(phone_number, country_code)
  end

  # Pour ActiveAdmin (Ransack)
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "first_name", "last_name", "email", "phone_number", "country_code",
     "user_type", "notified_at", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def log_creation
    Rails.logger.info("🔔 [MaintenanceNotification] Inscription créée - id: #{id}, email: #{email}, téléphone: #{phone_number}, nom: #{first_name} #{last_name}, type: #{user_type_label}")
  end

  def phone_number_format
    return if phone_number.blank? || country_code.blank?

    service = PhoneValidationService.new(phone_number, country_code)
    unless service.valid?
      error_msg = service.error_message
      errors.add(:phone_number, error_msg) if error_msg
    end
  end
end
