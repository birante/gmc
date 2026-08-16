class Payment < ApplicationRecord
  belongs_to :order
  belongs_to :payment_method

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    refunded: 4
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "amount", "created_at", "id", "order_id", "paid_at", "paydunya_invoice_url", "payment_method_id", "payment_type", "status", "transaction_id", "updated_at", "user_id", "withdraw_mode" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "order", "payment_method" ]
  end

  before_create :generate_transaction_id
  after_create :log_payment_creation
  after_update :log_payment_status_change, if: :saved_change_to_status?
  # TODO: Envoyer SMS de confirmation de paiement
  # Ajouter un callback après la confirmation du paiement:
  # after_update :send_payment_confirmation_sms, if: -> { saved_change_to_status? && completed? }
  #
  # private
  # def send_payment_confirmation_sms
  #   return unless order&.user&.phone_number.present?
  #   message = "Votre paiement de #{amount} #{order.currency&.symbol || order.currency&.code} pour la commande ##{order.id} a été confirmé. Merci!"
  #   Sms::SmsService.new.send_sms(
  #     to: order.user.formatted_phone_number,
  #     message: message,
  #     sms_type: "notification"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS confirmation paiement: #{e.message}")
  # end
  #
  # TODO: Envoyer SMS d'échec de paiement
  # Ajouter un callback après l'échec du paiement:
  # after_update :send_payment_failed_sms, if: -> { saved_change_to_status? && failed? }
  #
  # private
  # def send_payment_failed_sms
  #   return unless order&.user&.phone_number.present?
  #   message = "Le paiement de votre commande ##{order.id} a échoué. Veuillez réessayer ou contacter le support."
  #   Sms::SmsService.new.send_sms(
  #     to: order.user.formatted_phone_number,
  #     message: message,
  #     sms_type: "alert"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS échec paiement: #{e.message}")
  # end

  private

  def generate_transaction_id
    self.transaction_id ||= "TXN-#{Time.current.to_i}-#{SecureRandom.hex(4).upcase}"
  end

  def log_payment_creation
    Rails.logger.info("💰 [Payment] Paiement créé - payment_id: #{id}, order_id: #{order_id}, montant: #{amount}, méthode: #{payment_method.name}, statut: #{status}")
  end

  def log_payment_status_change
    Rails.logger.info("✏️ [Payment] Changement statut paiement - payment_id: #{id}, ancien_statut: #{status_before_last_save}, nouveau_statut: #{status}")
  end

  public

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "order_id", "payment_method_id", "amount", "transaction_id", "status", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "order", "payment_method" ]
  end
end
