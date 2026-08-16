ActiveAdmin.register VariantAttributeValue do
  menu parent: "Catalogue", priority: 10, label: "Valeurs Attributs Variantes", if: false
  permit_params :item_variant_id, :attribute_value_id

  actions :all

  filter :item_variant
  filter :attribute_value
  filter :created_at

  index do
    selectable_column
    id_column
    column :item_variant
    column "Attribut" do |vav|
      vav.attribute_value.item_attribute.name
    end
    column "Valeur" do |vav|
      vav.attribute_value.value
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :item_variant
      row :attribute_value
      row "Attribut" do |vav|
        vav.attribute_value.item_attribute.name
      end
      row "Valeur" do |vav|
        vav.attribute_value.value
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Association Variante-Valeur d'attribut" do
      f.input :item_variant
      f.input :attribute_value
    end
    f.actions
  end
end
