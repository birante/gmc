module Checkout
  # Service de finalisation de commande (checkout final)
  #
  # Responsabilités:
  #   - Crée la commande (Order) depuis le panier
  #   - Crée les OrderItems avec adresses de livraison
  #   - Crée le paiement (Payment) et lance le processus
  #   - Vide le panier après succès
  #   - Envoie les notifications (email/SMS)
  #
  # Flux:
  #   1. Validation du contexte (panier non vide, user connecté)
  #   2. Création Order + OrderItems + Payment en transaction
  #   3. Traitement du paiement (Paydunya, Cash, etc.)
  #   4. Marquage du panier comme complété
  #   5. Redirection vers Paydunya si nécessaire
  #
  # Usage:
  #   service = Checkout::FinalizeOrderService.new(
  #     user: current_user,
  #     cart: session_cart,
  #     params: {
  #       payment_method_id: 1,
  #       shipping_address_id: 123
  #     }
  #   )
  #   result = service.call
  #   if result.success?
  #     redirect_to result.paydunya_redirect_url || order_path(result.order)
  #   end
  #
  # @see Order
  # @see Payment
  # @see Cart
  class FinalizeOrderService
    Result = Struct.new(:success?, :order, :errors, :paydunya_redirect_url, keyword_init: true)

    def initialize(user:, cart:, params:)
      @user = user
      @cart = cart
      @params = params
      @errors = []
      @order_repository = OrderRepository.new
      @cart_repository = CartRepository.new
    end

    def call
      start_time = Time.current
      Rails.logger.info("🛒 [Checkout::FinalizeOrderService] ========== FINALISATION COMMANDE ==========")
      Rails.logger.info("📋 [Checkout::FinalizeOrderService] User ID: #{user.id} | Cart ID: #{cart.id} | Items: #{cart.cart_items.count}")
      Rails.logger.info("💰 [Checkout::FinalizeOrderService] Montant panier: #{cart.total_amount}")

      validate_context
      if errors.any?
        duration = (Time.current - start_time).round(3)
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Validation échouée après #{duration}s - #{errors.join(', ')}")
        return failure
      end
      Rails.logger.info("✅ [Checkout::FinalizeOrderService] Validation réussie - Méthode: #{@payment_method.name} | Zone: #{@delivery_zone.name}")

      ActiveRecord::Base.transaction do
        transaction_start = Time.current
        Rails.logger.info("🚀 [Checkout::FinalizeOrderService] Début transaction DB")

        build_order
        # Sauvegarder l'ordre (build_for_user crée un objet non sauvegardé)
        order.save!
        Rails.logger.info("📦 [Checkout::FinalizeOrderService] Order créée - ID: #{order.id} | Total: #{order.total_amount} | Livraison: #{order.delivery_fee} | Final: #{order.final_amount}")

        items_start = Time.current
        build_order_items
        items_duration = (Time.current - items_start).round(3)
        Rails.logger.info("📝 [Checkout::FinalizeOrderService] OrderItems créés en #{items_duration}s - Count: #{order.order_items.count}")

        payment_start = Time.current
        build_payment
        payment.save!
        payment_duration = (Time.current - payment_start).round(3)
        Rails.logger.info("💳 [Checkout::FinalizeOrderService] Payment créé en #{payment_duration}s - ID: #{payment.id} | Méthode: #{payment.payment_method.name} | Status: #{payment.status}")

        process_start = Time.current
        process_payment_for_provider
        process_duration = (Time.current - process_start).round(3)
        Rails.logger.info("⚡ [Checkout::FinalizeOrderService] Paiement traité en #{process_duration}s")

        @cart_repository.complete!(cart)
        transaction_duration = (Time.current - transaction_start).round(3)
        Rails.logger.info("🗑️ [Checkout::FinalizeOrderService] Panier complété - Cart ID: #{cart.id} | Transaction: #{transaction_duration}s")

        # TODO: Envoyer SMS de confirmation de commande
        # Le SMS sera envoyé automatiquement par le callback after_create de Order
        # Mais on peut aussi envoyer un SMS ici pour confirmer la création immédiate:
        # if user.phone_number.present?
        #   message = "Votre commande ##{order.id} a été créée avec succès. Montant: #{order.final_amount} #{order.currency&.symbol || order.currency&.code}."
        #   Sms::SmsService.new.send_sms(
        #     to: user.formatted_phone_number,
        #     message: message,
        #     sms_type: "notification"
        #   )
        # rescue Sms::SmsService::SmsDisabledError => e
        #   Rails.logger.info("SMS désactivé, notification non envoyée")
        # rescue StandardError => e
        #   Rails.logger.error("Erreur envoi SMS confirmation: #{e.message}")
        # end
      end

      total_duration = (Time.current - start_time).round(3)
      Rails.logger.info("✅ [Checkout::FinalizeOrderService] Commande finalisée avec succès en #{total_duration}s - Order ID: #{order.id}")
      success
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Checkout::FinalizeOrderService] Erreur validation après #{duration}s - User: #{user.id}")
      Rails.logger.error("❌ [Checkout::FinalizeOrderService] #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Checkout::FinalizeOrderService] Backtrace: #{e.backtrace.first(3).join('\n')}")
      errors << e.message
      failure
    rescue StandardError => e
      duration = (Time.current - start_time).round(3)
      Rails.logger.error("❌ [Checkout::FinalizeOrderService] EXCEPTION après #{duration}s - #{e.class}: #{e.message}")
      Rails.logger.error("❌ [Checkout::FinalizeOrderService] Backtrace: #{e.backtrace.first(5).join('\n')}")
      # Transmettre le message d'erreur spécifique si disponible
      error_message = if e.message.present? && !e.message.include?("#<")
        e.message
      else
        "Une erreur inattendue est survenue lors de la finalisation de la commande."
      end
      errors << error_message
      failure
    end

    attr_reader :order, :payment, :errors, :paydunya_redirect_url

    private

    attr_reader :user, :cart, :params

    def validate_context
      Rails.logger.info("🔍 [Checkout::FinalizeOrderService] Validation contexte...")

      if cart.blank? || cart.cart_items.empty?
        errors << "Votre panier est vide"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Panier vide ou inexistant")
        return
      end
      Rails.logger.info("📊 [Checkout::FinalizeOrderService] Panier valide - #{cart.cart_items.count} item(s)")

      @address = if params[:address_id].present?
        find_address(params[:address_id])
      else
        user.default_address
      end
      if @address.nil?
        errors << "Veuillez sélectionner une adresse de livraison"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Adresse de livraison manquante")
      else
        Rails.logger.info("📍 [Checkout::FinalizeOrderService] Adresse: #{@address.street_address}")
      end

      @delivery_zone = DeliveryZone.active.find_by(id: params[:delivery_zone_id])
      if @delivery_zone.nil?
        errors << "Zone de livraison non disponible"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Zone de livraison invalide - ID: #{params[:delivery_zone_id]}")
      else
        Rails.logger.info("🌍 [Checkout::FinalizeOrderService] Zone: #{@delivery_zone.name}")
      end

      @delivery_slot = @delivery_zone&.delivery_slots&.active&.find_by(id: params[:delivery_slot_id])
      if @delivery_slot.nil?
        errors << "Créneau de livraison invalide"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Créneau invalide - ID: #{params[:delivery_slot_id]}")
      else
        Rails.logger.info("⏰ [Checkout::FinalizeOrderService] Créneau: #{@delivery_slot.time_range}")
      end

      # Déterminer la méthode de paiement
      if params[:payment_method] == "cash_on_delivery"
        # Cash à la livraison
        @payment_method = PaymentMethod.active.find_by(code: "cash_on_delivery")
        if @payment_method.nil?
          errors << "Mode de paiement Cash à la livraison non disponible"
          Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Cash on delivery non disponible")
        else
          Rails.logger.info("💵 [Checkout::FinalizeOrderService] Mode: Cash à la livraison ou ")
        end
        @is_cash_on_delivery = true
      elsif params[:payment_method].present?
        # Paiement en ligne: mapper la valeur frontend vers le code DB
        requested_payment_code = resolve_online_payment_method_code(params[:payment_method])
        @payment_method = PaymentMethod.active.find_by(code: requested_payment_code)

        # Fallback rétrocompatible: ancien mode unique paydunya
        @payment_method ||= PaymentMethod.active.find_by(code: "paydunya")

        if @payment_method.nil?
          errors << "Mode de paiement PayDunya non disponible"
          Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Paiement en ligne non disponible - demandé: #{params[:payment_method]} | code mappé: #{requested_payment_code}")
        else
          Rails.logger.info("📱 [Checkout::FinalizeOrderService] Mode en ligne: #{@payment_method.code} (frontend: #{params[:payment_method]})")
        end
        @is_cash_on_delivery = false
      else
        errors << "Veuillez sélectionner une méthode de paiement"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Aucune méthode de paiement sélectionnée")
      end

      validate_cart_item_payment_rules
    end

    def validate_cart_item_payment_rules
      pm = params[:payment_method].to_s
      return if pm.blank?

      if pm == "cash_on_delivery" && cart.cash_on_delivery_blocked?
        errors << "Un ou plusieurs articles ne sont pas disponibles en paiement cash à la livraison"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Cash refusé par règle produit")
        return
      end

      return if pm == "cash_on_delivery"

      allowed = cart.effective_allowed_payment_codes
      if allowed.nil?
        nil
      elsif allowed.empty?
        errors << "Aucun mode de paiement en ligne n'est compatible avec tous les articles du panier"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Intersection des modes autorisés vide")
      elsif !allowed.include?(pm)
        errors << "Le mode de paiement sélectionné n'est pas autorisé pour tous les articles du panier"
        Rails.logger.warn("⚠️ [Checkout::FinalizeOrderService] Mode #{pm} hors liste autorisée: #{allowed.inspect}")
      end
    end

    def find_address(identifier)
      user.addresses.friendly.find(identifier)
    rescue ActiveRecord::RecordNotFound
      user.addresses.find_by(id: identifier)
    end

    def resolve_online_payment_method_code(front_value)
      case front_value.to_s
      when "wave-senegal" then "wave_sn"
      when "orange-money-senegal" then "orange_money_sn"
      when "free-money-senegal" then "free_money_sn"
      when "expresso-senegal" then "expresso_sn"
      else
        front_value.to_s
      end
    end


    def build_order
      total_amount = cart.total_amount

      # Calculer les frais de livraison basés sur la catégorie la plus grande
      delivery_fee = calculate_delivery_fee

      order_attributes = {
        delivery_zone: @delivery_zone,
        delivery_slot: @delivery_slot,
        delivery_address: @address.street_address,
        currency: cart.cart_items.first.item.currency,
        status: "pending",
        notes: params[:notes],
        total_amount: total_amount,
        delivery_fee: delivery_fee,
        final_amount: total_amount + delivery_fee
      }

      @order = @order_repository.build_for_user(user, order_attributes)
    end

    # Calcule les frais de livraison basés sur la catégorie de livraison la plus grande
    def calculate_delivery_fee
      return 0.0 unless @delivery_zone.present?

      # Récupérer toutes les catégories de livraison des produits du panier
      categories = cart.cart_items.includes(item: :delivery_category)
                        .map { |ci| ci.item&.delivery_category }
                        .compact

      if categories.empty?
        Rails.logger.info("📦 [Checkout::FinalizeOrderService] Aucune catégorie, frais de base: #{@delivery_zone.base_fee}")
        return @delivery_zone.base_fee || 0.0
      end

      # Trouver la catégorie la plus grande (celle avec le display_order le plus élevé)
      largest_category = DeliveryCategory.largest_among(categories)
      unless largest_category.present?
        Rails.logger.info("📦 [Checkout::FinalizeOrderService] Pas de catégorie principale, frais de base: #{@delivery_zone.base_fee}")
        return @delivery_zone.base_fee || 0.0
      end

      # Utiliser le prix spécifique pour cette catégorie et cette zone
      delivery_price = DeliveryPrice.find_price(@delivery_zone.id, largest_category.id)
      final_fee = delivery_price > 0 ? delivery_price : (@delivery_zone.base_fee || 0.0)

      Rails.logger.info("📦 [Checkout::FinalizeOrderService] Frais calculés - Catégorie: #{largest_category.name} | Frais: #{final_fee}")
      final_fee
    end

    def build_order_items
      cart.cart_items.find_each do |cart_item|
        variant = cart_item.variant
        raise ActiveRecord::RecordNotFound, "Variante non trouvée pour l'article #{cart_item.item&.name}" unless variant

        order.order_items.create!(
          item: cart_item.item,
          item_variant: variant,
          shop: cart_item.item.shop,
          quantity: cart_item.quantity,
          unit_price: cart_item.unit_price,
          total_price: cart_item.total_price,
          delivery_status: "pending_shipment"
        )

        variant.decrement!(:stock_quantity, cart_item.quantity)
      end
    end

    def build_payment
      payment_status = @is_cash_on_delivery ? "completed" : "pending"

      @payment = order.payments.new(
        payment_method: @payment_method,
        amount: order.final_amount,
        status: payment_status,
        user_id: user.id,
        transaction_id: generate_transaction_id,
        withdraw_mode: params[:withdraw_mode]
      )

      # Pour cash on delivery, marquer comme payé immédiatement
      if @is_cash_on_delivery
        @payment.paid_at = Time.current
      end
    end

    def process_payment_for_provider
      if @is_cash_on_delivery
        # Pas de traitement pour cash on delivery, déjà marqué comme completed
        Rails.logger.info("💵 [Checkout::FinalizeOrderService] Cash on delivery - Payment ID: #{payment.id} | Montant: #{payment.amount}")
      else
        # Traitement PayDunya
        process_paydunya_payment
      end
    end

    def generate_transaction_id
      provider = @payment_method.provider.to_s.upcase
      prefix = case provider
      when "CASH_ON_DELIVERY", "INTERNAL" then "COD"
      when "CARD", "CINETPAY/PAYGATE" then "CARD"
      else provider
      end
      "#{prefix}-#{SecureRandom.hex(8)}"
    end

    def process_paydunya_payment
      paydunya_start = Time.current
      Rails.logger.info("🚀 [Checkout::FinalizeOrderService] Traitement PayDunya - Order: #{order.id} | Montant: #{payment.amount} | Mode: #{params[:withdraw_mode]}")

      # Utiliser le nouveau service HTTP PayDunya
      service = PaymentServices::PaydunyaHttpService.new(
        payment: payment,
        order: order,
        user: user
      )

      # Créer l'invoice avec redirection (PAR)
      result = service.create_checkout_invoice

      unless result.success?
        paydunya_duration = (Time.current - paydunya_start).round(3)
        Rails.logger.error("❌ [Checkout::FinalizeOrderService] Échec PayDunya après #{paydunya_duration}s - #{result.errors.join(', ')}")
        raise StandardError, result.errors.join(", ")
      end

      # Stocker l'URL de redirection pour la récupérer dans le contrôleur
      @paydunya_redirect_url = result.redirect_url
      paydunya_duration = (Time.current - paydunya_start).round(3)
      Rails.logger.info("✅ [Checkout::FinalizeOrderService] Invoice PayDunya créée en #{paydunya_duration}s - Payment: #{payment.id} | URL: #{result.redirect_url}")
    end


    def success
      Result.new(success?: true, order: order, errors: [], paydunya_redirect_url: @paydunya_redirect_url)
    end

    def failure
      Result.new(success?: false, order: order, errors: errors, paydunya_redirect_url: nil)
    end
  end
end
