class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item
  belongs_to :item_variant, optional: true
  belongs_to :shop

  before_validation :sync_total_price_from_quantity
  before_validation :assign_shop_from_item

  enum :delivery_status, {
    # Par défaut. Le produit n'a pas encore été expédié/livré.
    pending_shipment: "pending_shipment",
    # Expédié par le vendeur/partenaire logistique.
    shipped: "shipped",
    # Livraison partielle - certains articles livrés, d'autres en attente.
    partial_delivery: "partial_delivery",
    # Arrivé chez le client.
    delivered: "delivered",
    # Impossible de livrer cet article (ex: rupture de stock tardive, erreur).
    failed: "failed",
    # Article retourné par le client.
    returned: "returned"
  }

  # Callbacks pour logging
  after_create :log_creation
  after_update :log_delivery_status_change, if: -> { saved_change_to_delivery_status? }
  after_update :credit_shop_on_delivery, if: -> { saved_change_to_delivery_status? && delivery_status == "delivered" }
  # Mettre à jour automatiquement le statut de la commande quand un article change de statut
  after_update :update_order_status_from_items, if: -> { saved_change_to_delivery_status? }
  # Envoyer une notification (email si disponible, SMS désactivé pour l'instant) quand un article change de statut
  after_update :notify_status_change, if: -> { saved_change_to_delivery_status? }
  after_commit :sync_parent_order_totals, on: [ :create, :update, :destroy ]

  # TODO: Réactiver SMS de notification de livraison d'article plus tard
  # def send_item_delivered_sms
  #   return unless order&.user&.phone_number.present?
  #   # Vérifier si tous les articles sont livrés pour envoyer un message global
  #   if order.order_items.all? { |oi| oi.delivery_status == "delivered" }
  #     # Tous les articles sont livrés, le SMS sera envoyé par le callback de Order.deliver
  #     return
  #   end
  #   # Sinon, envoyer un SMS pour cet article spécifique
  #   message = "Un article de votre commande ##{order.id} (#{item.name}) a été livré avec succès."
  #   Sms::SmsService.new.send_sms(
  #     to: order.user.formatted_phone_number,
  #     message: message,
  #     sms_type: "notification"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS livraison article: #{e.message}")
  # end

  private

  def sync_total_price_from_quantity
    return unless quantity.present? && unit_price.present?

    self.total_price = (quantity.to_d * unit_price.to_d).round(2)
  end

  def assign_shop_from_item
    return unless item_id.present? && item

    self.shop_id = item.shop_id if shop_id.blank? || shop_id != item.shop_id
  end

  def sync_parent_order_totals
    return unless order_id.present? && order.present?

    order.recalculate_amounts_from_line_items!
  rescue StandardError => e
    Rails.logger.warn("⚠️ [OrderItem] sync_parent_order_totals: #{e.message}")
  end

  def update_order_status_from_items
    return unless order.present?

    # Recharger la commande pour avoir les dernières données des items
    order.reload

    # Mettre à jour le statut de la commande automatiquement
    # Cette méthode calcule le statut en fonction de tous les statuts des items
    old_order_status = order.status
    order.calculate_status_from_items!

    # Vérifier si le statut a changé
    order.reload
    if old_order_status != order.status
      Rails.logger.info("✅ [OrderItem] Statut commande mis à jour automatiquement - order_id: #{order.id}, order_item_id: #{id}, ancien_statut: #{old_order_status}, nouveau_statut: #{order.status}, delivery_status_item: #{delivery_status}")
    else
      Rails.logger.debug("ℹ️ [OrderItem] Statut commande inchangé - order_id: #{order.id}, statut: #{order.status}, delivery_status_item: #{delivery_status}")
    end
  rescue StandardError => e
    Rails.logger.error("❌ [OrderItem] Erreur mise à jour statut commande - order_item_id: #{id}, order_id: #{order&.id}, erreur: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
  end

  def log_creation
    Rails.logger.info("📦 [OrderItem] Article de commande créé - order_item_id: #{id}, order_id: #{order_id}, item_id: #{item_id}, shop_id: #{shop_id}, quantité: #{quantity}, prix: #{unit_price}, total: #{total_price}")
  end

  def log_delivery_status_change
    old_status, new_status = saved_change_to_delivery_status
    Rails.logger.info("🚚 [OrderItem] Changement statut livraison - order_item_id: #{id}, order_id: #{order_id}, ancien_statut: #{old_status}, nouveau_statut: #{new_status}")
  end

  def credit_shop_on_delivery
    FinanceManager.credit_shop_for_order_item(self)
  end

  def notify_status_change
    return unless order.present?
    return unless order.user.present?

    old_status, new_status = saved_change_to_delivery_status
    return if old_status == new_status
    return if new_status == "pending_shipment" # Pas de notification pour le statut initial

    begin
      user = order.user

      # Envoyer une notification email si l'email est disponible
      # Note : SMS désactivé pour l'instant (peut être réactivé plus tard)
      has_email = user.respond_to?(:email_address) && user.email_address.present?
      has_email ||= user.respond_to?(:email) && user.email.present?

      if has_email
        Notifications::NotificationService.send_order_item_status_change(
          order_item: self,
          old_status: old_status,
          send_sms: false, # SMS désactivé pour l'instant
          send_whatsapp: false,
          send_email: true
        )

        Rails.logger.info("📧 [OrderItem] Notification email envoyée - order_item_id: #{id}, order_id: #{order.id}, statut: #{old_status} → #{new_status}, recipient: #{user.email_address || user.email}")
      else
        # Pas d'email disponible et SMS désactivé : notification non envoyée
        Rails.logger.info("ℹ️ [OrderItem] Notification non envoyée - order_item_id: #{id}, order_id: #{order.id}, statut: #{old_status} → #{new_status}, email non disponible, SMS désactivé")
      end
    rescue StandardError => e
      Rails.logger.error("❌ [OrderItem] Erreur envoi notification - order_item_id: #{id}, order_id: #{order&.id}, erreur: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
    end
  end

  public

  # Retourne les statuts de livraison vers lesquels on peut transitionner depuis l'état actuel
  def available_next_delivery_statuses
    case delivery_status
    when "pending_shipment"
      # Depuis pending_shipment, on peut expédier, marquer comme échoué ou retourné
      [ "shipped", "failed", "returned" ]
    when "shipped"
      # Depuis shipped, on peut livrer, marquer comme échoué ou retourné
      [ "delivered", "failed", "returned" ]
    when "delivered"
      # Une fois livré, on peut seulement le marquer comme retourné
      [ "returned" ]
    when "failed"
      # Échec de livraison : on peut réessayer (pending_shipment) ou marquer comme retourné
      [ "pending_shipment", "returned" ]
    when "returned"
      # Retourné : état final, pas de changement possible
      []
    else
      []
    end
  end

  # Vérifie si on peut changer vers un nouveau statut
  def can_change_to_delivery_status?(new_status)
    available_next_delivery_statuses.include?(new_status.to_s) || new_status.to_s == delivery_status
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "order_id", "item_id", "item_variant_id", "shop_id", "quantity", "unit_price", "total_price", "delivery_status", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "order", "item", "item_variant", "shop" ]
  end
end
