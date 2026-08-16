# frozen_string_literal: true

# Modèle pour les inscriptions en attente de vérification OTP
#
# Stocke temporairement les données d'inscription (User ou Vendor) avant validation OTP.
# Les données sensibles sont chiffrées et automatiquement nettoyées après expiration.
#
# Flux d'inscription:
#   1. User/Vendor remplit le formulaire d'inscription
#   2. PendingRegistration créé avec OTP généré
#   3. OTP envoyé par SMS ou Email
#   4. User/Vendor vérifie le code OTP
#   5. Si valide: compte créé, PendingRegistration marqué comme vérifié
#   6. Nettoyage automatique des enregistrements expirés/vérifiés
#
# Sécurité:
#   - encrypted_data chiffré via Rails.application.credentials
#   - OTP expire après ttl_seconds (défaut: 5 minutes)
#   - Nettoyage automatique via cleanup_expired! et cleanup_verified!
#
# == Schema Information
#
# Table name: pending_registrations
#
#  id              :bigint           not null, primary key
#  user_type       :string           not null
#  email           :string
#  phone_number    :string
#  encrypted_data  :text             not null
#  otp_code        :string           not null
#  otp_expires_at  :datetime         not null
#  verified_at     :datetime
#  channel         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class PendingRegistration < ApplicationRecord
  # Chiffrement des données utilisateur
  encrypts :encrypted_data

  # Validations
  validates :user_type, presence: true, inclusion: { in: %w[User Vendor] }
  validates :otp_code, presence: true
  validates :otp_expires_at, presence: true
  validates :encrypted_data, presence: true
  validates :channel, inclusion: { in: %w[sms email], allow_nil: true }

  # Scopes
  scope :active, -> { where("otp_expires_at > ?", Time.current).where(verified_at: nil) }
  scope :expired, -> { where("otp_expires_at <= ?", Time.current) }
  scope :verified, -> { where.not(verified_at: nil) }
  scope :for_user, -> { where(user_type: "User") }
  scope :for_vendor, -> { where(user_type: "Vendor") }

  # Méthodes
  def expired?
    otp_expires_at <= Time.current
  end

  def verified?
    verified_at.present?
  end

  def active?
    !expired? && !verified?
  end

  def mark_as_verified!
    update!(verified_at: Time.current)
  end

  # Récupérer les données déchiffrées
  def registration_data
    JSON.parse(encrypted_data, symbolize_names: true)
  end

  # Nettoyer les enregistrements expirés (à exécuter périodiquement)
  def self.cleanup_expired!(older_than: 24.hours.ago)
    expired.where("created_at < ?", older_than).delete_all
  end

  # Nettoyer les enregistrements vérifiés (compte créé)
  def self.cleanup_verified!(older_than: 1.hour.ago)
    verified.where("verified_at < ?", older_than).delete_all
  end

  # Ransack — autoriser explicitement les attributs et associations recherchables
  def self.ransackable_attributes(auth_object = nil)
    %w[id user_type email phone_number channel otp_expires_at verified_at created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  # Logs
  after_create :log_creation
  after_update :log_update, if: :saved_changes?

  private

  def log_creation
    Rails.logger.info("🔐 [PendingRegistration] Créé - ID: #{id}, type: #{user_type}, email: #{email}, phone: #{phone_number}, expires: #{otp_expires_at}")
  end

  def log_update
    Rails.logger.info("🔐 [PendingRegistration] Mis à jour - ID: #{id}, changements: #{saved_changes.except('updated_at').keys.join(', ')}")
  end
end
