ActiveAdmin.register ItemVariant do
  menu parent: "Catalogue", priority: 5, label: "Variantes"
  permit_params :item_id, :sku, :price, :stock_quantity, :is_default

  actions :all, except: [ :destroy ]

  filter :item
  filter :sku
  filter :price
  filter :stock_quantity
  filter :is_default
  filter :created_at

  index do
    selectable_column
    id_column
    column :item
    column :sku
    column "Variante par défaut" do |iv|
      status_tag(iv.is_default? ? "Oui" : "Non", class: iv.is_default? ? "ok" : "no")
    end
    column "Attributs" do |iv|
      iv.formatted_attributes.presence || "—"
    end
    column "Prix" do |iv|
      number_to_currency(iv.price, unit: "FCFA", separator: ",", delimiter: " ")
    end
    column "Stock" do |iv|
      status_tag(iv.in_stock? ? iv.stock_quantity.to_s : "Rupture", class: iv.in_stock? ? "ok" : "error")
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :item
      row :sku
      row "Variante par défaut" do |iv|
        status_tag(iv.is_default? ? "Oui" : "Non", class: iv.is_default? ? "ok" : "no")
      end
      row "Attributs" do |iv|
        iv.formatted_attributes.presence || "—"
      end
      row "Prix" do |iv|
        number_to_currency(iv.price, unit: "FCFA", separator: ",", delimiter: " ")
      end
      row "Stock" do |iv|
        iv.stock_quantity
      end
      row "En stock" do |iv|
        status_tag(iv.in_stock? ? "Oui" : "Non", class: iv.in_stock? ? "ok" : "error")
      end
      row :created_at
      row :updated_at
    end

    panel "Valeurs d'attributs" do
      table_for resource.variant_attribute_values.includes(:attribute_value) do
        column "Attribut" do |vav|
          vav.attribute_value.item_attribute.name
        end
        column "Valeur" do |vav|
          vav.attribute_value.value
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de la variante" do
      f.input :item
      f.input :sku
      f.input :price, as: :number, step: 0.01
      f.input :stock_quantity, as: :number
      f.input :is_default, label: "Variante par défaut"
    end
    f.actions
  end
end
