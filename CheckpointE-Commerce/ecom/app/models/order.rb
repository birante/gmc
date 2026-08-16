class Order < ApplicationRecord
  extend FriendlyId
  include AASM

  friendly_id :slug_candidates, use: :slugged

  belongs_to :user
  belongs_to :delivery_zone
  belongs_to :delivery_slot
  belongs_to :currency
  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :order_status_histories, dependent: :destroy
  accepts_nested_attributes_for :order_items, allow_destroy: false
  # Note: shop_transactions sont liées via order_items.shop, pas directement à Order

  # State machine avec AASM
  # Le statut de la commande est maintenant calculé automatiquement à partir des statuts des articles
  aasm column: :status, whiny_transitions: false do
    state :pending, initial: true
    state :processing
    state :shipped
    state :partial_delivery  # Livraison partielle : certains articles livrés, d'autres non
    state :delivered
    state :canceled

    # Événement : Commencer le traitement
    event :process do
      # TODO: Réactiver SMS de notification de traitement plus tard
      # transitions from: :pending, to: :processing, after: [ :create_status_history_entry, :send_processing_notification_sms ]
      # Permet de passer de pending à processing (calcul automatique depuis items)
      transitions from: :pending, to: :processing, after: [ :create_status_history_entry, :send_processing_notification_email ]
    end

    # Événement : Expédier
    event :ship do
      # TODO: Réactiver SMS de notification d'expédition plus tard
      # transitions from: [ :pending, :processing ], to: :shipped, after: [ :create_status_history_entry_and_set_departure_date, :send_shipped_notification_sms ]
      # Permet de passer de pending/processing à shipped, ou de partial_delivery à shipped (si tous delivered sont annulés)
      transitions from: [ :pending, :processing, :partial_delivery ], to: :shipped, after: [ :create_status_history_entry_and_set_departure_date, :send_shipped_notification_email ]
    end

    # Événement : Livraison partielle
    event :mark_partial_delivery do
      # Permet de passer à partial_delivery depuis processing, shipped, ou de rester en partial_delivery
      # Aussi depuis pending si des articles sont livrés directement (cas rare)
      transitions from: [ :pending, :processing, :shipped, :partial_delivery ], to: :partial_delivery, after: [ :create_status_history_entry, :send_partial_delivery_notification_email ]
    end

    # Événement : Livrer
    event :deliver do
      # TODO: Réactiver SMS de notification de livraison plus tard
      # transitions from: [ :processing, :shipped, :partial_delivery ], to: :delivered, after: [ :create_status_history_entry, :send_delivered_notification_sms ]
      # Permet de passer à delivered depuis processing, shipped, partial_delivery, ou même pending (cas rare)
      transitions from: [ :pending, :processing, :shipped, :partial_delivery ], to: :delivered, after: [ :create_status_history_entry, :send_delivered_notification_email ]
    end

    # Événement : Annuler (peut être fait depuis n'importe quel état sauf delivered)
    event :cancel do
      # TODO: Réactiver SMS de notification d'annulation plus tard
      # transitions from: [ :pending, :processing, :shipped, :partial_delivery ], to: :canceled, after: [ :create_status_history_entry, :send_canceled_notification_sms ]
      transitions from: [ :pending, :processing, :shipped, :partial_delivery ], to: :canceled, after: [ :create_status_history_entry, :send_canceled_notification_email ]
    end
  end

  after_create :log_order_creation
  after_create :create_initial_status_history
  # TODO: Envoyer SMS de confirmation de commande au client
  # Ajouter un callback after_create pour envoyer un SMS:
  after_create :send_order_confirmation_sms
  after_create :notify_vendors_of_new_order

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "currency_id", "delivery_address", "delivery_fee", "delivery_slot_id", "delivery_zone_id", "departure_date", "estimated_arrival_date", "final_amount", "id", "notes", "slug", "status", "total_amount", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user", "delivery_zone", "delivery_slot", "currency", "order_items", "payments", "order_status_histories" ]
  end

  private
  def send_order_confirmation_sms
    Notifications::NotificationService.send_order_confirmation(
      self,
      send_sms: false, # Désactivé pour le client à la création de commande
      send_email: false
    )
  end

  def notify_vendors_of_new_order
    # Récupérer tous les shops uniques de la commande
    shops = order_items.includes(:shop).map(&:shop).uniq

    shops.each do |shop|
      vendor = shop.vendor
      next unless vendor

      # Envoyer les notifications (email actif, SMS en TODO)
      Notifications::NotificationService.send_vendor_new_order(
        vendor: vendor,
        order: self,
        shop: shop,
        send_sms: false, # TODO: Réactiver SMS plus tard
        send_email: true
      )
    end
  end

  def slug_candidates
    [
      [ :id, :user_id ],
      [ :id, :user_id, :created_at ]
    ]
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  # Détermine la catégorie de livraison requise (la plus grande)
  def required_delivery_category
    categories = order_items.includes(item: :delivery_category)
                           .map { |oi| oi.item&.delivery_category }
                           .compact

    return nil if categories.empty?
    DeliveryCategory.largest_among(categories)
  end

  # Calcule les frais de livraison basés sur la zone et la catégorie
  def calculate_delivery_fee
    return 0.0 unless delivery_zone_id.present?

    category = required_delivery_category
    return 0.0 unless category.present?

    DeliveryPrice.find_price(delivery_zone_id, category.id)
  end

  # Met à jour le total avec les frais de livraison
  def update_totals!
    self.delivery_fee = calculate_delivery_fee
    self.final_amount = total_amount + delivery_fee
    save!
  end

  # Recalcule total_amount depuis les lignes puis frais et montant final (admin / ajustements manuels)
  def recalculate_amounts_from_line_items!
    reload
    self.total_amount = order_items.sum(:total_price)
    self.delivery_fee = calculate_delivery_fee
    self.final_amount = total_amount + delivery_fee.to_f
    save!
  end

  private

  def log_order_creation
    Rails.logger.info("📦 [Order] Commande créée - order_id: #{id}, user_id: #{user_id}, montant_total: #{total_amount}, montant_final: #{final_amount}, statut: #{aasm.current_state}")
  end

  def create_initial_status_history(changed_by: nil)
    # Vérifier si la table existe avant d'essayer de créer l'historique
    return unless ActiveRecord::Base.connection.table_exists?(:order_status_histories)

    order_status_histories.create!(
      status: aasm.current_state.to_s,
      note: status_message_for_status(aasm.current_state.to_s),
      changed_by: changed_by
    )
  rescue => e
    Rails.logger.error("❌ [Order] Erreur création historique initial - order_id: #{id}, erreur: #{e.message}")
    # Ne pas faire échouer la création de la commande si l'historique échoue
  end

  # Callback AASM : Créer l'entrée d'historique après transition
  # Note: changed_by et note sont récupérés depuis current_status_changer et current_status_note (définis avant l'événement)
  def create_status_history_entry
    # Vérifier si la table existe avant d'essayer de créer l'historique
    return unless ActiveRecord::Base.connection.table_exists?(:order_status_histories)

    note_text = current_status_note || status_message_for_status(aasm.current_state.to_s)
    order_status_histories.create!(
      status: aasm.current_state.to_s,
      note: note_text,
      changed_by: current_status_changer
    )
  rescue => e
    Rails.logger.error("❌ [Order] Erreur création historique - order_id: #{id}, erreur: #{e.message}")
  end

  # Callback AASM : Créer l'historique et définir departure_date pour l'expédition
  def create_status_history_entry_and_set_departure_date
    self.departure_date = Time.current if departure_date.nil?
    save! if departure_date_changed?
    create_status_history_entry
  end

  # Attributs temporaires pour stocker qui change le statut et la note (utilisés dans les contrôleurs)
  attr_accessor :current_status_changer, :current_status_note

  def status_message_for_status(status_key)
    case status_key
    when "pending"
      I18n.t("orders.status_history.pending", default: "Votre commande a été effectuée avec succès")
    when "processing"
      I18n.t("orders.status_history.processing", default: "Votre commande est en cours de traitement par le vendeur")
    when "shipped"
      I18n.t("orders.status_history.shipped", default: "Votre commande est en route")
    when "partial_delivery"
      I18n.t("orders.status_history.partial_delivery", default: "Votre commande est partiellement livrée")
    when "delivered"
      I18n.t("orders.status_history.delivered", default: "Votre commande a été livrée avec succès")
    when "canceled"
      I18n.t("orders.status_history.canceled", default: "Votre commande a été annulée")
    else
      nil
    end
  end

  public

  # Calcule automatiquement le statut de la commande à partir des statuts des articles
  # Cette méthode est appelée automatiquement quand un article change de statut
  def calculate_status_from_items!
    return if canceled? # Ne pas modifier le statut si la commande est annulée

    # Recharger les items pour avoir les dernières données
    items = order_items.reload
    return if items.empty?

    # Compter les statuts des articles (exclure failed et returned pour le calcul principal)
    active_items = items.reject { |item| [ "failed", "returned" ].include?(item.delivery_status) }
    return if active_items.empty? # Si tous les articles sont failed/returned, garder le statut actuel

    delivered_count = active_items.count { |item| item.delivery_status == "delivered" }
    shipped_count = active_items.count { |item| item.delivery_status == "shipped" }
    pending_shipment_count = active_items.count { |item| item.delivery_status == "pending_shipment" }
    total_active_count = active_items.count

    # Logique de calcul du statut (par ordre de priorité)
    # NOTE: Les conditions sont vérifiées dans un ordre spécifique pour garantir la priorité correcte
    new_status = if delivered_count == total_active_count
      # Cas 1: Tous les articles actifs sont livrés → commande livrée
      # Exemple: [delivered, delivered, delivered]
      "delivered"
    elsif delivered_count > 0 && delivered_count < total_active_count
      # Cas 2: Certains articles sont livrés, d'autres non → livraison partielle
      # Exemple: [delivered, shipped, pending_shipment] ou [delivered, pending_shipment]
      "partial_delivery"
    elsif shipped_count > 0
      # Cas 3: Au moins un article est expédié (mais aucun livré) → expédié
      # Exemple: [shipped, shipped, pending_shipment] ou [shipped, pending_shipment]
      "shipped"
    elsif pending_shipment_count < total_active_count
      # Cas 4: Au moins un article a été traité (expédié ou livré) mais tous retombent à pending
      # Ce cas ne devrait pas arriver normalement car on ne peut pas revenir en arrière,
      # mais peut arriver si un article failed est remis à pending_shipment
      # Exemple: [pending_shipment, pending_shipment] avec un article qui était shipped (mais maintenant failed/returned)
      # Dans ce cas, si on n'a que pending_shipment actif, on va au else
      "processing"
    else
      # Cas 5: Tous les articles actifs sont en attente d'expédition → en attente
      # Exemple: [pending_shipment, pending_shipment, pending_shipment]
      "pending"
    end

    # Mettre à jour le statut seulement s'il a changé
    if new_status != status
      Rails.logger.info("🔄 [Order] Calcul automatique du statut - order_id: #{id}, ancien: #{status}, nouveau: #{new_status} (livrés: #{delivered_count}/#{total_active_count}, expédiés: #{shipped_count}, en_attente: #{pending_shipment_count})")
      success = update_status!(new_status, changed_by: nil, note: "Statut calculé automatiquement à partir des articles")

      if success
        # Recharger pour avoir le statut mis à jour
        reload
        Rails.logger.info("✅ [Order] Statut commande mis à jour avec succès - order_id: #{id}, nouveau_statut: #{status}")
      else
        Rails.logger.error("❌ [Order] Échec mise à jour statut - order_id: #{id}, nouveau_statut: #{new_status}")
      end
    else
      Rails.logger.debug("ℹ️ [Order] Statut inchangé - order_id: #{id}, statut: #{status} (livrés: #{delivered_count}/#{total_active_count})")
    end
  rescue StandardError => e
    Rails.logger.error("❌ [Order] Erreur calcul automatique statut - order_id: #{id}, erreur: #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))
  end

  # Méthode publique pour changer le statut via AASM avec historique
  # Utilise les événements AASM pour garantir les transitions valides
  def update_status!(new_status, changed_by: nil, note: nil)
    self.current_status_changer = changed_by
    self.current_status_note = note

    old_state = aasm.current_state

    # Mapper le nouveau statut vers l'événement AASM approprié
    case new_status.to_s
    when "processing"
      process!
    when "shipped"
      ship!
    when "partial_delivery"
      mark_partial_delivery!
    when "delivered"
      deliver!
    when "canceled", "cancelled"
      cancel!
    when "pending"
      # pending est l'état initial, on ne peut pas y retourner automatiquement
      # Mais on peut le faire manuellement si nécessaire (pour réinitialiser)
      if changed_by.present?
        # Permettre le retour à pending seulement si fait manuellement
        self.status = "pending"
        save!
        create_status_history_entry
      else
        # Si calcul automatique, on ne peut pas revenir à pending
        # Le statut pending ne peut être que l'état initial
        Rails.logger.warn("⚠️ [Order] Tentative de retour à pending via calcul automatique - order_id: #{id}, ignoré")
        return false
      end
    else
      Rails.logger.error("❌ [Order] Statut invalide - order_id: #{id}, statut: #{new_status}")
      return false
    end

    # L'historique est créé automatiquement par les callbacks AASM
    Rails.logger.info("✅ [Order] Statut mis à jour via AASM - order_id: #{id}, de #{old_state} vers #{aasm.current_state}")
    true
  rescue AASM::InvalidTransition => e
    Rails.logger.error("❌ [Order] Transition invalide - order_id: #{id}, de #{old_state} vers #{new_status}, erreur: #{e.message}")
    false
  end

  # Méthode de compatibilité avec l'ancien code (pour l'historique manuel si nécessaire)
  def track_status_change!(changed_by: nil, note: nil)
    # Vérifier si la table existe avant d'essayer de créer l'historique
    return unless ActiveRecord::Base.connection.table_exists?(:order_status_histories)

    self.current_status_changer = changed_by
    order_status_histories.create!(
      status: aasm.current_state.to_s,
      note: note || status_message_for_status(aasm.current_state.to_s),
      changed_by: changed_by
    )
  rescue => e
    Rails.logger.error("❌ [Order] Erreur création historique manuel - order_id: #{id}, erreur: #{e.message}")
  end

  # Méthodes pour envoyer les notifications de changement de statut (utilisent le service centralisé)
  def send_processing_notification_email
    Notifications::NotificationService.send_order_status_change(
      order: self,
      status: :processing,
      send_sms: false, # TODO: Réactiver SMS plus tard
      send_email: true
    )
  end

  def send_shipped_notification_email
    Notifications::NotificationService.send_order_status_change(
      order: self,
      status: :shipped,
      send_sms: false, # TODO: Réactiver SMS plus tard
      send_email: true
    )
  end

  def send_delivered_notification_email
    Notifications::NotificationService.send_order_status_change(
      order: self,
      status: :delivered,
      send_sms: false, # TODO: Réactiver SMS plus tard
      send_email: true
    )
  end

  def send_canceled_notification_email
    Notifications::NotificationService.send_order_status_change(
      order: self,
      status: :canceled,
      send_sms: false, # TODO: Réactiver SMS plus tard
      send_email: true
    )
  end

  def send_partial_delivery_notification_email
    Notifications::NotificationService.send_order_status_change(
      order: self,
      status: :partial_delivery,
      send_sms: false, # TODO: Réactiver SMS plus tard
      send_email: true
    )
  end

  # TODO: Réactiver les SMS de notification de changement de statut plus tard
  # Méthodes pour envoyer les SMS de notification de changement de statut (actuellement désactivées)
  #
  # def send_processing_notification_sms
  #   return unless user&.phone_number.present?
  #   message = "Votre commande ##{id} est en cours de traitement. Nous vous tiendrons informé de l'avancement."
  #   Sms::SmsService.new.send_sms(
  #     to: user.formatted_phone_number,
  #     message: message,
  #     sms_type: "notification"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS traitement: #{e.message}")
  # end

  # def send_shipped_notification_sms
  #   return unless user&.phone_number.present?
  #   departure_info = departure_date ? "Le #{departure_date.strftime('%d/%m/%Y à %H:%M')}" : "Aujourd'hui"
  #   message = "Votre commande ##{id} a été expédiée! #{departure_info}. Elle arrivera bientôt."
  #   Sms::SmsService.new.send_sms(
  #     to: user.formatted_phone_number,
  #     message: message,
  #     sms_type: "notification"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS expédition: #{e.message}")
  # end

  # def send_delivered_notification_sms
  #   return unless user&.phone_number.present?
  #   message = "Votre commande ##{id} a été livrée avec succès! Merci d'avoir fait vos achats chez nous."
  #   Sms::SmsService.new.send_sms(
  #     to: user.formatted_phone_number,
  #     message: message,
  #     sms_type: "notification"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS livraison: #{e.message}")
  # end

  # def send_canceled_notification_sms
  #   return unless user&.phone_number.present?
  #   message = "Votre commande ##{id} a été annulée. Si vous avez des questions, contactez notre service client."
  #   Sms::SmsService.new.send_sms(
  #     to: user.formatted_phone_number,
  #     message: message,
  #     sms_type: "alert"
  #   )
  # rescue Sms::SmsService::SmsDisabledError => e
  #   Rails.logger.info("SMS désactivé, notification non envoyée")
  # rescue StandardError => e
  #   Rails.logger.error("Erreur envoi SMS annulation: #{e.message}")
  # end

  # Date de départ (stockée ou calculée)
  def departure_date_or_estimated
    departure_date || estimated_departure_date
  end

  # Calculer la date de départ estimée (basée sur delivery_slot)
  def estimated_departure_date
    return nil unless delivery_slot&.start_time

    # Si la commande est en processing ou shipped, utiliser created_at + un délai
    if aasm.current_state == :processing || aasm.current_state == :shipped
      created_at + 1.day
    else
      created_at
    end
  end

  # Date d'arrivée estimée (stockée ou basée sur delivery_slot)
  def arrival_date_or_estimated
    estimated_arrival_date || delivery_slot&.end_time
  end

  # Numéro de commande formaté pour l'affichage
  def order_number
    "##{id}"
  end

  # Obtenir toutes les boutiques de cette commande (via order_items)
  def shops
    Shop.joins(:order_items).where(order_items: { order_id: id }).distinct
  end

  # Retourne les statuts vers lesquels on peut transitionner depuis l'état actuel
  def available_next_statuses
    case aasm.current_state
    when :pending
      [ "processing", "shipped", "canceled" ]
    when :processing
      [ "shipped", "delivered", "canceled" ]
    when :shipped
      [ "delivered", "canceled" ]
    when :delivered, :canceled
      [] # États finaux
    else
      []
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "user_id", "delivery_zone_id", "delivery_slot_id", "currency_id", "total_amount", "delivery_fee", "final_amount", "status", "delivery_address", "notes", "departure_date", "estimated_arrival_date", "created_at", "updated_at", "slug" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user", "delivery_zone", "delivery_slot", "currency", "order_items", "payments" ]
  end
end
