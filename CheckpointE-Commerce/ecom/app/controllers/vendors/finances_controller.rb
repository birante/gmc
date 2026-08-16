class Vendors::FinancesController < Vendors::BaseController
  def index
    @vendor = current_vendor
    return redirect_to vendors_dashboard_path, alert: "Vendeur non trouvé" unless @vendor

    # Utiliser les variables définies par VendorShopContext
    if @current_shop
      # Si on a une boutique active, utiliser uniquement celle-ci
      @shops = [ @current_shop ]
      shop_ids = [ @current_shop.id ]
    else
      # Sinon, utiliser toutes les boutiques du vendeur
      @shops = @vendor.shops.order(created_at: :desc)
      shop_ids = @shops.pluck(:id)
    end

    # Calculer le solde total
    @total_balance = @shops.sum(&:balance)

    # Transactions récentes
    @recent_transactions = ShopTransaction.where(shop_id: shop_ids)
                                         .includes(:order, :payout, :shop, :currency)
                                         .order(created_at: :desc)
                                         .limit(20)

    # Payouts récents
    @recent_payouts = Payout.where(shop_id: shop_ids)
                           .includes(:shop, :currency)
                           .order(created_at: :desc)
                           .limit(10)

    # Montant en attente de reversement
    @pending_payout_amount = @shops.sum(&:pending_payout_amount)
  end

  def transactions
    @vendor = current_vendor
    return redirect_to vendors_dashboard_path, alert: "Vendeur non trouvé" unless @vendor

    shop_ids = shop_ids_for_context

    @transactions = ShopTransaction.where(shop_id: shop_ids)
                                  .includes(:order, :payout, :shop, :currency)
                                  .order(created_at: :desc)

    # Filtres
    @transactions = @transactions.where(transaction_type: params[:type]) if params[:type].present?
    @transactions = @transactions.where(shop_id: params[:shop_id]) if params[:shop_id].present? && shop_ids.include?(params[:shop_id].to_i)

    # Pagination (utiliser Kaminari si disponible, sinon limite simple)
    if defined?(Kaminari)
      @transactions = @transactions.page(params[:page]).per(50)
    else
      @transactions = @transactions.limit(50).offset((params[:page].to_i - 1) * 50)
    end
  end

  def payouts
    @vendor = current_vendor
    return redirect_to vendors_dashboard_path, alert: "Vendeur non trouvé" unless @vendor

    shop_ids = shop_ids_for_context

    @payouts = Payout.where(shop_id: shop_ids)
                    .includes(:shop, :currency, shop_transactions: [ :order ])
                    .order(created_at: :desc)

    # Filtres
    @payouts = @payouts.where(status: params[:status]) if params[:status].present?
    @payouts = @payouts.where(shop_id: params[:shop_id]) if params[:shop_id].present? && shop_ids.include?(params[:shop_id].to_i)

    # Pagination
    if defined?(Kaminari)
      @payouts = @payouts.page(params[:page]).per(20)
    else
      @payouts = @payouts.limit(20).offset((params[:page].to_i - 1) * 20)
    end
  end

  def show_payout
    @vendor = current_vendor
    return redirect_to vendors_dashboard_path, alert: "Vendeur non trouvé" unless @vendor

    shop_ids = shop_ids_for_context

    @payout = Payout.where(id: params[:id], shop_id: shop_ids)
                   .includes(:shop, :currency, shop_transactions: [ :order ])
                   .first

    unless @payout
      redirect_to payouts_vendors_finances_path(shop_slug: @current_shop&.slug), alert: "Reversement non trouvé"
    end
  end

  private

  def shop_ids_for_context
    @shop_ids ||= if @current_shop
      [ @current_shop.id ]
    else
      current_vendor.shops.pluck(:id)
    end
  end
end
