ActiveAdmin.register ItemAttribute do
  menu parent: "Catalogue", priority: 7, label: "Attributs Produit", if: false

  belongs_to :item
  permit_params :name, :position, attribute_values_attributes: [ :id, :value, :position, :_destroy ]

  actions :all

  menu false  # Cacher du menu principal, accessible via le parent

  filter :id
  filter :name
  filter :position
  filter :item
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :name
    column :position
    column "Nombre de valeurs" do |attr|
      attr.attribute_values.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :name
      row :position
      row :created_at
      row :updated_at
    end

    panel "Valeurs de l'attribut" do
      table_for resource.attribute_values.ordered do
        column :value
        column :position
        column { |value| link_to "Éditer", edit_admin_item_item_attribute_attribute_value_path(resource.item_id, resource.id, value), class: "button" }
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name, label: "Nom de l'attribut (ex: Couleur, Taille, Processeur)"
      f.input :position, label: "Position", as: :number
    end

    f.inputs "Valeurs de l'attribut" do
      f.has_many :attribute_values, allow_destroy: true, new_record: true do |v|
        v.input :value, label: "Valeur"
        v.input :position, label: "Position", as: :number
      end
    end

    f.actions
  end
end
