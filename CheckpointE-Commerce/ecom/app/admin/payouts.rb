ActiveAdmin.register Payout do
  menu parent: "Finance", priority: 3, label: "Paiements Vendeurs"

  # Specify parameters which should be permitted for assignment
  permit_params :shop_id, :currency_id, :amount, :status, :reference_number, :paid_at, :payout_month, :payout_year

  # For security, limit the actions that should be available
  actions :all, except: [ :destroy ]

  # Action membre pour créer un reversement automatique depuis une boutique
  member_action :create_payout_for_shop, method: :post do
    shop = Shop.find(params[:shop_id])
    total_to_pay = shop.pending_payout_amount

    if total_to_pay > 0
      begin
        FinanceManager.process_monthly_payout(shop)
        redirect_to admin_payouts_path, notice: "Reversement créé avec succès pour #{shop.name} (#{number_to_currency(total_to_pay, unit: shop.currency&.symbol || 'FCFA')})"
      rescue StandardError => e
        redirect_to admin_payouts_path, alert: "Erreur lors de la création du reversement : #{e.message}"
      end
    else
      redirect_to admin_payouts_path, alert: "Aucun montant à reverser pour #{shop.name}"
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :shop
  filter :status, as: :select, collection: Payout.statuses.keys
  filter :amount
  filter :currency
  filter :payout_month
  filter :payout_year
  filter :reference_number
  filter :paid_at
  filter :created_at

  # Scopes pour filtrer par statut
  scope :all, default: true
  scope :pending
  scope :processing
  scope :paid
  scope :failed

  # Action membre pour créer un payout manuel
  member_action :mark_as_paid, method: :patch do
    payout = resource

    # Vérifier si une transaction de débit existe déjà (créée lors de process_monthly_payout)
    debit_transaction = payout.shop_transactions.find_by(transaction_type: "debit")

    unless debit_transaction
      Rails.logger.warn("⚠️ [Admin::Payouts] Payout marqué comme payé sans transaction de débit - payout_id: #{payout.id}, shop_id: #{payout.shop_id}, montant: #{payout.amount}")
    end

    payout.update!(
      status: "paid",
      paid_at: Time.current,
      reference_number: params[:reference_number] || payout.reference_number
    )

    Rails.logger.info("✅ [Admin::Payouts] Payout marqué comme payé - payout_id: #{payout.id}, shop_id: #{payout.shop_id}, montant: #{payout.amount}, reference: #{payout.reference_number}")

    redirect_to resource_path(resource), notice: "Payout marqué comme payé"
  end

  # Action membre pour traiter le payout
  member_action :process_payout, method: :patch do
    resource.update!(status: "processing")
    redirect_to resource_path(resource), notice: "Payout en cours de traitement"
  end

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :shop do |payout|
      link_to payout.shop.name, admin_shop_path(payout.shop) if payout.shop
    end
    column :amount do |payout|
      number_to_currency(payout.amount, unit: payout.currency&.symbol || "FCFA")
    end
    column :currency
    column :status do |payout|
      status_class = case payout.status
      when "paid" then "ok"
      when "pending" then "warning"
      when "processing" then "yes"
      when "failed" then "error"
      else "no"
      end
      status_tag payout.status, class: status_class
    end
    column "Période" do |payout|
      "#{payout.payout_month}/#{payout.payout_year}"
    end
    column :reference_number
    column :paid_at
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :shop do |payout|
        link_to payout.shop.name, admin_shop_path(payout.shop) if payout.shop
      end
      row :currency do |payout|
        "#{payout.currency&.name} (#{payout.currency&.symbol})" if payout.currency
      end
      row :amount do |payout|
        number_to_currency(payout.amount, unit: payout.currency&.symbol || "FCFA")
      end
      row :status do |payout|
        status_class = case payout.status
        when "paid" then "ok"
        when "pending" then "warning"
        when "processing" then "yes"
        when "failed" then "error"
        else "no"
        end
        status_tag payout.status, class: status_class
      end
      row "Période" do |payout|
        "#{payout.payout_month}/#{payout.payout_year}"
      end
      row :reference_number
      row :paid_at
      row :created_at
      row :updated_at
    end

    panel "Transactions associées" do
      credit_transactions = payout.shop_transactions.where(transaction_type: "credit").includes(:order)
      if credit_transactions.any?
        table_for credit_transactions do
          column :id
          column :description
          column :order do |transaction|
            if transaction.order
              link_to "Commande ##{transaction.order.id}", admin_order_path(transaction.order)
            else
              "-"
            end
          end
          column :amount do |transaction|
            number_to_currency(transaction.amount, unit: transaction.currency&.symbol || "FCFA")
          end
          column :created_at
        end

        div style: "margin-top: 15px; padding: 10px; background-color: #f0f0f0; border-radius: 4px;" do
          strong "Total: #{number_to_currency(payout.amount, unit: payout.currency&.symbol || 'FCFA')}"
        end
      else
        para "Aucune transaction associée"
      end
    end

    # Actions selon le statut
    if payout.pending?
      panel "Actions" do
        div do
          form_tag process_payout_admin_payout_path(payout), method: :patch, style: "display: inline-block; margin-right: 10px;" do
            submit_tag "Marquer comme 'En traitement'", class: "button"
          end

          form_tag mark_as_paid_admin_payout_path(payout), method: :patch, style: "display: inline-block;" do
            div style: "display: inline-block; margin-right: 10px;" do
              label "Référence:", for: "reference_number"
              text_field_tag "reference_number", payout.reference_number, placeholder: "Numéro de référence"
            end
            submit_tag "Marquer comme payé", class: "button"
          end
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations du reversement" do
      f.input :shop
      f.input :currency
      f.input :amount, hint: "Montant à reverser", min: 0.01
      f.input :status, as: :select, collection: Payout.statuses.keys
      f.input :reference_number, hint: "Numéro de référence du virement"
      f.input :paid_at, as: :string, input_html: { type: "datetime-local", value: f.object.paid_at&.strftime("%Y-%m-%dT%H:%M") }
    end

    f.inputs "Période" do
      f.input :payout_month, as: :select, collection: (1..12).map { |m| [ Date::MONTHNAMES[m], m ] }
      f.input :payout_year, as: :number, hint: "Année (ex: 2024)"
    end

    f.actions
  end
end
