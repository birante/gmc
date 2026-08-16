ActiveAdmin.register AttributeValue do
  menu parent: "Catalogue", priority: 8, label: "Valeurs Attributs", if: false

  belongs_to :item_attribute
  permit_params :value, :position

  actions :all

  menu false  # Cacher du menu principal, accessible via le parent

  filter :id
  filter :value
  filter :position
  filter :item_attribute
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :value
    column :position
    column :item_attribute
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :value
      row :position
      row :item_attribute
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :value, label: "Valeur"
      f.input :position, label: "Position", as: :number
    end

    f.actions
  end
end
