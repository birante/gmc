ActiveAdmin.register SubscriptionPayment do
  menu parent: "💰 Finances", priority: 4

  permit_params :shop_id, :plan_id, :payment_method_id, :amount, :status

  scope :all, default: true
  scope :pending
  scope :completed
  scope :failed

  filter :shop
  filter :plan
  filter :payment_method
  filter :withdraw_mode, as: :select, collection: -> { SubscriptionPayment.distinct.pluck(:withdraw_mode).compact }
  filter :status, as: :select, collection: SubscriptionPayment.statuses.keys
  filter :amount
  filter :created_at
  filter :paid_at

  index do
    selectable_column
    id_column
    column :shop do |sp|
      link_to sp.shop.name, admin_shop_path(sp.shop)
    end
    column :plan do |sp|
      status_tag sp.plan.code, class: "ok"
    end
    column :amount do |sp|
      number_to_currency(sp.amount, unit: "FCFA", separator: ",", delimiter: " ", format: "%n %u")
    end
    column :payment_method
    column :withdraw_mode do |sp|
      sp.withdraw_mode&.humanize || "—"
    end
    column :status do |sp|
      case sp.status
      when "completed"
        status_tag "Complété", class: "ok"
      when "pending"
        status_tag "En attente", class: "warning"
      when "failed"
        status_tag "Échoué", class: "error"
      when "processing"
        status_tag "En cours", class: "info"
      end
    end
    column :paid_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :shop do |sp|
        link_to sp.shop.name, admin_shop_path(sp.shop)
      end
      row :plan do |sp|
        status_tag sp.plan.code, class: "ok"
      end
      row :payment_method
      row :amount do |sp|
        number_to_currency(sp.amount, unit: "FCFA", separator: ",", delimiter: " ", format: "%n %u")
      end
      row :status do |sp|
        status_tag sp.status
      end
      row :withdraw_mode do |sp|
        sp.withdraw_mode&.humanize || "—"
      end
      row :transaction_id
      row :paydunya_token
      row :paydunya_invoice_url do |sp|
        if sp.paydunya_invoice_url.present?
          link_to "Voir la facture PayDunya", sp.paydunya_invoice_url, target: "_blank", rel: "noopener"
        end
      end
      row :paid_at
      row :failure_reason
      row :provider_response do |sp|
        if sp.provider_response.present?
          pre JSON.pretty_generate(sp.provider_response)
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Détails du paiement" do
      f.input :shop, as: :select, collection: Shop.order(:name)
      f.input :plan, as: :select, collection: Plan.active.order(:name)
      f.input :payment_method, as: :select, collection: PaymentMethod.active.order(:name)
      f.input :amount, as: :number, step: 0.01
      f.input :status, as: :select, collection: SubscriptionPayment.statuses.keys
    end
    f.actions
  end
end
