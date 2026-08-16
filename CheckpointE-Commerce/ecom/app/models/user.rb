class User < ApplicationRecord
  has_secure_password
  has_many :sessions, as: :sessionable, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :destroy, counter_cache: :orders_count
  has_many :reviews, dependent: :destroy
  has_many :user_verifications, dependent: :delete_all

  # Email optionnel côté client : on convertit la chaîne vide en NULL pour que l'index
  # unique sur `email_address` n'empêche pas plusieurs users sans email de coexister
  # (PostgreSQL traite chaque NULL comme distinct dans un index unique standard).
  normalizes :email_address, with: ->(e) { e.to_s.strip.downcase.presence }
  normalizes :phone_number, with: ->(p) { p.to_s.strip.gsub(/\D/, "") }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone_number, presence: true, uniqueness: true
  validates :country_code, presence: true
  validates :email_address, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Validation personnalisée pour le numéro de téléphone
  validate :phone_number_format

  # Callbacks pour logging
  after_create :log_creation
  after_update :log_update, if: :saved_changes?

  private

  def log_creation
    Rails.logger.info("👤 [User] Utilisateur créé - user_id: #{id}, email: #{email_address}, téléphone: #{phone_number}, nom: #{first_name} #{last_name}")
  end

  def log_update
    changes_summary = saved_changes.except("updated_at", "password_digest").keys.join(", ")
    Rails.logger.info("✏️ [User] Utilisateur mis à jour - user_id: #{id}, champs modifiés: #{changes_summary}") if changes_summary.present?
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

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email_address", "first_name", "id", "last_name", "phone_number", "country_code", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "sessions", "carts", "addresses", "orders", "reviews", "user_verifications" ]
  end

  # Retourne le panier actif de l'utilisateur ou en crée un nouveau
  def current_cart
    carts.active.first_or_create
  end

  # Retourne l'adresse par défaut
  def default_address
    addresses.find_by(is_default: true) || addresses.first
  end

  # Méthode pour obtenir le nom complet
  def full_name
    "#{first_name} #{last_name}"
  end

  # Vérifie si le compte utilisateur a été vérifié
  # Un compte est considéré comme vérifié s'il a au moins une vérification utilisée (status = true)
  def verified?
    user_verifications.exists?(status: true)
  end

  # Retourne la dernière vérification utilisée
  def last_verification
    user_verifications.where(status: true).order(used_at: :desc).first
  end
end
