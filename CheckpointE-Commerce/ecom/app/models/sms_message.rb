# frozen_string_literal: true

# Modèle pour l'historique des SMS envoyés
#
# Chaque SMS envoyé via Sms::SmsService est enregistré dans cette table.
# Permet de suivre l'état d'envoi, les erreurs, et garder un historique.
#
# Attributs:
#   - from: Nom/numéro de l'expéditeur
#   - to: Numéro du destinataire (format E.164)
#   - body: Contenu du message SMS
#   - status: État d'envoi (pending/sending/sent/failed)
#   - sms_type: Type de SMS (verification/notification/alert)
#   - provider: Provider utilisé (orange_sn_service/lam_service)
#   - provider_response: Réponse JSON du provider
#
# Scopes:
#   - pending: SMS en attente
#   - sending: SMS en cours d'envoi
#   - sent: SMS envoyés avec succès
#   - failed: SMS échoués
#   - by_provider(provider): Filtre par provider
#   - recent: Triés par date décroissante
#
class SmsMessage < ApplicationRecord
  # Statuts possibles
  STATUSES = %w[pending sending sent failed].freeze

  # Types de SMS possibles
  SMS_TYPES = %w[verification notification alert].freeze

  # Providers disponibles
  PROVIDERS = %w[orange_sn_service lam_service].freeze

  validates :to, presence: true
  validates :body, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :sms_type, inclusion: { in: SMS_TYPES }, allow_nil: true
  validates :provider, inclusion: { in: PROVIDERS }, allow_nil: true

  scope :pending, -> { where(status: "pending") }
  scope :sending, -> { where(status: "sending") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
  scope :by_provider, ->(provider) { where(provider:) }
  scope :recent, -> { order(created_at: :desc) }

  # Retourne le statut sous forme de label
  def status_label
    case status
    when "pending"
      "En attente"
    when "sending"
      "En cours d'envoi"
    when "sent"
      "Envoyé"
    when "failed"
      "Échec"
    else
      status.humanize
    end
  end

  # Vérifie si le SMS a été envoyé avec succès
  def sent?
    status == "sent"
  end

  # Vérifie si le SMS a échoué
  def failed?
    status == "failed"
  end

  # Vérifie si le SMS est en cours d'envoi
  def sending?
    status == "sending"
  end

  # Vérifie si le SMS est en attente
  def pending?
    status == "pending"
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "to", "body", "status", "sms_type", "provider", "error_message", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
