ActiveAdmin.register DeliverySlot do
  menu parent: "Logistique", priority: 4, label: "Créneaux de Livraison"
  # Specify parameters which should be permitted for assignment
  permit_params :start_time, :end_time, :is_active

  # For security, limit the actions that should be available
  actions :all

  # Add or remove filters to toggle their visibility
  filter :id
  filter :start_time
  filter :end_time
  filter :is_active, as: :select, collection: { "Actif" => true, "Inactif" => false }
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column "Créneau" do |slot|
      slot.time_range
    end
    column :start_time do |slot|
      slot.start_time.strftime("%H:%M")
    end
    column :end_time do |slot|
      slot.end_time.strftime("%H:%M")
    end
    column "Zones" do |slot|
      slot.delivery_zones.count
    end
    column "Commandes" do |slot|
      slot.orders.count
    end
    column :is_active do |slot|
      if slot.is_active
        status_tag("Actif", class: "ok")
      else
        status_tag("Inactif", class: "error")
      end
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row "Créneau" do |slot|
        slot.time_range
      end
      row :start_time do |slot|
        slot.start_time.strftime("%H:%M")
      end
      row :end_time do |slot|
        slot.end_time.strftime("%H:%M")
      end
      row :is_active do |slot|
        if slot.is_active
          status_tag("Actif", class: "ok")
        else
          status_tag("Inactif", class: "error")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Zones de livraison associées" do
      table_for resource.delivery_zones do
        column "Zone" do |zone|
          link_to zone.name, admin_delivery_zone_path(zone)
        end
        column :description
        column :base_fee do |zone|
          number_to_currency(zone.base_fee, unit: "€")
        end
        column :is_active do |zone|
          if zone.is_active
            status_tag("Active", class: "ok")
          else
            status_tag("Inactive", class: "error")
          end
        end
      end
    end

    panel "Statistiques" do
      attributes_table_for resource do
        row "Nombre de commandes" do |slot|
          slot.orders.count
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :start_time, label: "Heure de début",
              as: :time_picker,
              hint: "Heure de début du créneau"
      f.input :end_time, label: "Heure de fin",
              as: :time_picker,
              hint: "Heure de fin du créneau"
      f.input :is_active, as: :boolean, label: "Créneau actif"
    end
    f.actions
  end
end
