ActiveAdmin.register Payment do
  menu parent: "Finance", priority: 4, label: "Paiements Clients"

  # Specify parameters which should be permitted for assignment
  permit_params :order_id, :payment_method_id, :amount, :transaction_id, :status

  # For security, limit the actions that should be available
  actions :all, except: [ :destroy ]

  # Add or remove filters to toggle their visibility
  filter :id
  filter :order
  filter :payment_method
  filter :amount
  filter :transaction_id
  filter :status, as: :select, collection: Payment.statuses.keys
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :order do |payment|
      link_to "##{payment.order_id}", admin_order_path(payment.order) if payment.order
    end
    column :payment_method do |payment|
      payment.payment_method&.name
    end
    column :amount do |payment|
      number_to_currency(payment.amount, unit: payment.order&.currency&.symbol || "€")
    end
    column :transaction_id
    column :status do |payment|
      status_tag payment.status, class: payment.status
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :order do |payment|
        link_to "##{payment.order_id}", admin_order_path(payment.order) if payment.order
      end
      row :payment_method do |payment|
        payment.payment_method&.name
      end
      row :amount do |payment|
        number_to_currency(payment.amount, unit: payment.order&.currency&.symbol || "€")
      end
      row :transaction_id
      row :status do |payment|
        status_tag payment.status, class: payment.status
      end
      row :created_at
      row :updated_at
    end

    if resource.order
      panel "Détails de la commande" do
        attributes_table_for resource.order do
          row :id do |order|
            link_to "##{order.id}", admin_order_path(order)
          end
          row :user do |order|
            link_to order.user&.full_name, admin_user_path(order.user) if order.user
          end
          row :total_amount do |order|
            number_to_currency(order.total_amount, unit: order.currency&.symbol || "€")
          end
          row :final_amount do |order|
            number_to_currency(order.final_amount, unit: order.currency&.symbol || "€")
          end
          row :status do |order|
            status_tag order.status, class: order.status
          end
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :order
      f.input :payment_method
      f.input :amount
      f.input :transaction_id, hint: "Généré automatiquement si vide"
      f.input :status, as: :select, collection: Payment.statuses.keys
    end
    f.actions
  end
end
