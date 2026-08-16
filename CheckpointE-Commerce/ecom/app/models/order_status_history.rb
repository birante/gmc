class OrderStatusHistory < ApplicationRecord
  belongs_to :order
  belongs_to :changed_by, polymorphic: true, optional: true

  validates :status, presence: true
  validates :status, inclusion: { in: %w[pending processing shipped delivered canceled] }

  scope :ordered, -> { order(created_at: :asc) }

  # Messages localisés pour chaque statut
  def status_message(locale: I18n.locale)
    case status
    when "pending"
      I18n.t("orders.status_history.pending", default: "Votre commande a été effectuée avec succès")
    when "processing"
      I18n.t("orders.status_history.processing", default: "Votre commande est en cours de traitement par le vendeur")
    when "shipped"
      I18n.t("orders.status_history.shipped", default: "Votre commande est en route")
    when "delivered"
      I18n.t("orders.status_history.delivered", default: "Votre commande a été livrée avec succès")
    when "canceled"
      I18n.t("orders.status_history.canceled", default: "Votre commande a été annulée")
    else
      note.presence || I18n.t("orders.status_history.default", default: "Statut de la commande mis à jour")
    end
  end

  # Libellé du statut pour l'affichage
  def status_label
    I18n.t("orders.status.#{status}", default: status.humanize)
  end

  # Qui a changé le statut (pour affichage)
  def changed_by_name
    return "Système" unless changed_by

    case changed_by_type
    when "User"
      changed_by.full_name
    when "Vendor"
      changed_by.full_name
    when "Employee"
      changed_by.full_name
    else
      "Administrateur"
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "order_id", "status", "note", "location", "changed_by_type", "changed_by_id", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "order" ]
  end
end
