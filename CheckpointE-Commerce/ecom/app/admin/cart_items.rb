ActiveAdmin.register CartItem do
  menu parent: "E-Commerce", priority: 3, label: "Articles de Panier"

  permit_params :cart_id, :item_id, :item_variant_id, :quantity

  actions :all, except: [ :destroy ]

  filter :cart
  filter :item
  filter :item_variant
  filter :quantity
  filter :created_at

  index do
    selectable_column
    id_column
    column :cart
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
    actions
  end

  show do
    attributes_table do
      row :id
      row :cart
      row :item
      row :item_variant
      row :quantity
      row "Prix unitaire" do |ci|
        number_to_currency(ci.unit_price, unit: "FCFA", separator: ",", delimiter: " ")
      end
      row "Prix total" do |ci|
        number_to_currency(ci.total_price, unit: "FCFA", separator: ",", delimiter: " ")
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de l'article du panier" do
      f.input :cart
      f.input :item
      f.input :item_variant
      f.input :quantity
    end
    f.actions
  end
end
