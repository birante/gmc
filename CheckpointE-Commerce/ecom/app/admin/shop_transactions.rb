ActiveAdmin.register ShopTransaction do
  menu parent: "Finance", priority: 5, label: "Transactions"

  # Specify parameters which should be permitted for assignment
  permit_params :shop_id, :order_id, :payout_id, :amount, :transaction_type, :description, :currency_id, metadata: {}

  # For security, limit the actions that should be available
  actions :all, except: [ :destroy, :edit, :new ]

  # Add or remove filters to toggle their visibility
  filter :id
  filter :shop
  filter :order
  filter :payout
  filter :transaction_type, as: :select, collection: %w[credit debit refund]
  filter :amount
  filter :currency
  filter :created_at

  # Scope pour filtrer
  scope :all, default: true
  scope :credits
  scope :debits
  scope :unpaid

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :shop do |transaction|
      link_to transaction.shop.name, admin_shop_path(transaction.shop) if transaction.shop
    end
    column :transaction_type do |transaction|
      status_tag transaction.transaction_type,
        class: transaction.transaction_type == "credit" ? "ok" : "error"
    end
    column :amount do |transaction|
      number_to_currency(transaction.amount, unit: transaction.currency&.symbol || "FCFA")
    end
    column :currency
    column :description
    column :order do |transaction|
      if transaction.order
        link_to "Commande ##{transaction.order.id}", admin_order_path(transaction.order)
      else
        "-"
      end
    end
    column :payout do |transaction|
      if transaction.payout
        link_to "Payout ##{transaction.payout.id}", admin_payout_path(transaction.payout)
      else
        status_tag "Non reversé", class: "warning"
      end
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :shop do |transaction|
        link_to transaction.shop.name, admin_shop_path(transaction.shop) if transaction.shop
      end
      row :transaction_type do |transaction|
        status_tag transaction.transaction_type,
          class: transaction.transaction_type == "credit" ? "ok" : "error"
      end
      row :amount do |transaction|
        number_to_currency(transaction.amount, unit: transaction.currency&.symbol || "FCFA")
      end
      row :currency
      row :description
      row :order do |transaction|
        if transaction.order
          link_to "Commande ##{transaction.order.id}", admin_order_path(transaction.order)
        else
          "-"
        end
      end
      row :payout do |transaction|
        if transaction.payout
          link_to "Payout ##{transaction.payout.id}", admin_payout_path(transaction.payout)
        else
          status_tag "Non reversé", class: "warning"
        end
      end
      # Afficher les informations de commission si c'est un crédit lié à une commande
      if resource.transaction_type == "credit" && resource.order
        commission_rate = FinanceManager.commission_fraction_for_shop(resource.shop)
        order_total = resource.order.total_amount.to_d
        commission_amount = order_total * commission_rate
        vendor_amount = order_total - commission_amount

        row "Taux commission aa" do
          number_to_percentage(commission_rate * 100, precision: 2)
        end
        row "Commission aa" do
          number_to_currency(commission_amount, unit: resource.currency&.symbol || "FCFA", precision: 0)
        end
        row "Montant commande" do
          number_to_currency(order_total, unit: resource.currency&.symbol || "FCFA", precision: 0)
        end
        row "Part vendeur" do
          number_to_currency(vendor_amount, unit: resource.currency&.symbol || "FCFA", precision: 0)
        end
      end
      row :metadata do |transaction|
        if transaction.metadata.present?
          pre JSON.pretty_generate(transaction.metadata)
        else
          "-"
        end
      end
      row :created_at
      row :updated_at
    end
  end
end
