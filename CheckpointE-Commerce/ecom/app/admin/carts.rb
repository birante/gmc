ActiveAdmin.register Cart do
  menu parent: "E-Commerce", priority: 2, label: "Paniers"

  permit_params :user_id, :status

  actions :all, except: [ :destroy ]

  filter :id
  filter :user
  filter :status, as: :select, collection: Cart::STATUSES
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :user
    column :status do |cart|
      status_tag cart.status, class: cart.status
    end
    column "Total articles" do |cart|
      cart.total_items_count
    end
    column "Montant total" do |cart|
      number_to_currency(cart.total_amount, unit: "FCFA", separator: ",", delimiter: " ")
    end
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :status do |cart|
        status_tag cart.status, class: cart.status
      end
      row "Total articles" do |cart|
        cart.total_items_count
      end
      row "Montant total" do |cart|
        number_to_currency(cart.total_amount, unit: "FCFA", separator: ",", delimiter: " ")
      end
      row :slug
      row :created_at
      row :updated_at
    end

    panel "Articles du panier" do
      table_for resource.cart_items.includes(:item, :item_variant) do
        column :item
        column :item_variant
        column :quantity
        column "Prix unitaire" do |ci|
          number_to_currency(ci.unit_price, unit: "FCFA", separator: ",", delimiter: " ")
        end
        column "Prix total" do |ci|
          number_to_currency(ci.total_price, unit: "FCFA", separator: ",", delimiter: " ")
        end
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations du panier" do
      f.input :user
      f.input :status, as: :select, collection: Cart::STATUSES
    end
    f.actions
  end
end
