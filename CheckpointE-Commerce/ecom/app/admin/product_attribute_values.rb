ActiveAdmin.register ProductAttributeValue do
  menu parent: "Catalogue", priority: 9, label: "Valeurs Attributs Produits", if: false
  permit_params :product_attribute_id, :value, :is_active

  actions :all

  filter :product_attribute
  filter :value
  filter :is_active
  filter :created_at

  index do
    selectable_column
    id_column
    column :product_attribute
    column :value
    column "Actif" do |pav|
      status_tag(pav.is_active? ? "Oui" : "Non", class: pav.is_active? ? "ok" : "no")
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :product_attribute
      row :value
      row "Actif" do |pav|
        status_tag(pav.is_active? ? "Oui" : "Non", class: pav.is_active? ? "ok" : "no")
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Valeur d'attribut produit" do
      f.input :product_attribute
      f.input :value
      f.input :is_active
    end
    f.actions
  end
end
