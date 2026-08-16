ActiveAdmin.register ProductAttribute do
  menu parent: "Catalogue", priority: 4, label: "Attributs Produits"

  permit_params :name, :description, :is_active,
                product_attribute_values_attributes: [ :id, :value, :is_active, :_destroy ]

  index do
    selectable_column
    id_column
    column :name
    column :description
    column "Valeurs" do |attr|
      attr.product_attribute_values.active.count
    end
    column :is_active
    column :created_at
    actions
  end

  filter :name
  filter :is_active
  filter :created_at

  form do |f|
    f.inputs "Informations de l'attribut" do
      f.input :name, label: "Nom"
      f.input :description, label: "Description"
      f.input :is_active, label: "Actif"
    end

    f.inputs "Valeurs de l'attribut" do
      f.has_many :product_attribute_values, allow_destroy: true, new_record: true do |v|
        v.input :value, label: "Valeur"
        v.input :is_active, label: "Active"
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :name
      row :description
      row :is_active
      row :created_at
      row :updated_at
    end

    panel "Valeurs" do
      table_for product_attribute.product_attribute_values do
        column :value
        column :is_active
        column :created_at
      end
    end

    active_admin_comments
  end
end
