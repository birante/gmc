# app/services/finance_manager.rb
class FinanceManager
  # Taux par défaut si la boutique n’a pas de valeur (rétrocompatibilité)
  DEFAULT_COMMISSION_RATE = 0.0

  # 1. Créditer la boutique lors de la livraison d'un article
  # Cette méthode est appelée quand un order_item est marqué comme "delivered"
  def self.credit_shop_for_order_item(order_item)
    return if order_item.delivery_status != "delivered"

    # Vérifier si une transaction n'a pas déjà été créée pour cet order_item spécifique
    # On vérifie dans les metadata
    existing_transaction = ShopTransaction.where(
      shop: order_item.shop,
      order: order_item.order,
      transaction_type: "credit"
    ).where("metadata IS NOT NULL AND metadata->>'order_item_id' = ?", order_item.id.to_s).first

    return if existing_transaction.present?

    commission = commission_fraction_for_shop(order_item.shop)
    # Le montant à créditer est le total_price de l'article moins la commission
    amount_to_credit = order_item.total_price * (1 - commission)

    ActiveRecord::Base.transaction do
      # Créer la transaction d'historique
      transaction = ShopTransaction.create!(
        shop: order_item.shop,
        order: order_item.order,
        payout: nil, # Sera rempli lors du reversement mensuel
        amount: amount_to_credit,
        transaction_type: "credit",
        description: "Vente de la commande ##{order_item.order.slug} - #{order_item.item&.name || 'Article supprimé'}",
        currency: order_item.order.currency,
        metadata: { order_item_id: order_item.id }
      )

      # Mettre à jour le solde en temps réel
      order_item.shop.increment!(:balance, amount_to_credit)

      Rails.logger.info("💰 [FinanceManager] Boutique créditée - shop_id: #{order_item.shop.id}, order_item_id: #{order_item.id}, montant: #{amount_to_credit}, transaction_id: #{transaction.id}")
    end
  end

  # 2. Effectuer le reversement mensuel (Payout)
  def self.process_monthly_payout(shop)
    ActiveRecord::Base.transaction do
      transactions_to_pay = shop.shop_transactions.unpaid
      total_to_pay = transactions_to_pay.sum(:amount)

      return if total_to_pay <= 0

      # Créer le record de Payout
      payout = Payout.create!(
        shop: shop,
        currency: shop.currency,
        amount: total_to_pay,
        status: "pending",
        payout_month: Time.current.month,
        payout_year: Time.current.year
      )

      # Lier les transactions au payout et marquer comme payées
      transactions_to_pay.update_all(payout_id: payout.id)

      # Créer une transaction de débit pour l'historique du solde
      debit_transaction = ShopTransaction.create!(
        shop: shop,
        order: nil, # Pas de commande pour un débit de reversement
        payout: payout,
        amount: total_to_pay,
        transaction_type: "debit",
        description: "Reversement mensuel vers votre compte",
        currency: shop.currency
      )

      # Stocker l'ancien solde pour le log
      old_balance = shop.balance

      # Déduire du solde de la boutique
      shop.decrement!(:balance, total_to_pay)

      new_balance = shop.balance

      Rails.logger.info("💰 [FinanceManager] Reversement créé - shop_id: #{shop.id}, payout_id: #{payout.id}, montant: #{total_to_pay}, solde_avant: #{old_balance}, solde_apres: #{new_balance}, debit_transaction_id: #{debit_transaction.id}")
      Rails.logger.info("💰 [FinanceManager] Solde boutique décrémenté - shop_id: #{shop.id}, montant_débité: #{total_to_pay}, nouveau_solde: #{new_balance}")
    end
  end

  # Part de commission aa (0..1), configurable par boutique (admin)
  def self.commission_fraction_for_shop(shop)
    rate = shop&.commission_rate
    rate = DEFAULT_COMMISSION_RATE if rate.nil?
    r = rate.to_f
    r = DEFAULT_COMMISSION_RATE if r.negative? || r > 1
    r
  end
end
