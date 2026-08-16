ActiveAdmin.register ZoneSlot do
  menu parent: "Logistique", priority: 5, label: "Zone-Créneaux"
  permit_params :delivery_zone_id, :delivery_slot_id

  actions :all

  filter :delivery_zone
  filter :delivery_slot
  filter :created_at

  index do
    selectable_column
    id_column
    column :delivery_zone
    column :delivery_slot
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :delivery_zone
      row :delivery_slot
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Association Zone-Créneau" do
      f.input :delivery_zone
      f.input :delivery_slot
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:delivery_zone, :delivery_slot)
    end
  end
end
