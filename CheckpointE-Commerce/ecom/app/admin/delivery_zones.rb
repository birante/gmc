ActiveAdmin.register DeliveryZone do
  menu parent: "Logistique", priority: 1, label: "Zones de Livraison"
  # Specify parameters which should be permitted for assignment
  permit_params :name, :description, :base_fee, :is_active

  # For security, limit the actions that should be available
  actions :all

  # Add or remove filters to toggle their visibility
  filter :id
  filter :name
  filter :description
  filter :base_fee
  filter :is_active, as: :select, collection: { "Active" => true, "Inactive" => false }
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :name
    column :description
    column :base_fee do |zone|
      number_to_currency(zone.base_fee, unit: "€")
    end
    column "Créneaux" do |zone|
      zone.delivery_slots.count
    end
    column "Adresses" do |zone|
      zone.addresses.count
    end
    column :is_active do |zone|
      if zone.is_active
        status_tag("Active", class: "ok")
      else
        status_tag("Inactive", class: "error")
      end
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :name
      row :description
      row :base_fee do |zone|
        number_to_currency(zone.base_fee, unit: "€")
      end
      row :is_active do |zone|
        if zone.is_active
          status_tag("Active", class: "ok")
        else
          status_tag("Inactive", class: "error")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Créneaux de livraison disponibles" do
      table_for resource.delivery_slots do
        column "Créneau" do |slot|
          link_to slot.time_range, admin_delivery_slot_path(slot)
        end
        column :is_active do |slot|
          if slot.is_active
            status_tag("Actif", class: "ok")
          else
            status_tag("Inactif", class: "error")
          end
        end
      end
    end

    panel "Prix de livraison par catégorie" do
      table_for resource.delivery_prices.includes(:delivery_category) do
        column "Catégorie" do |dp|
          dp.delivery_category&.name
        end
        column "Taille" do |dp|
          dp.delivery_category&.size
        end
        column :price do |dp|
          number_to_currency(dp.price, unit: "€")
        end
      end
    end

    panel "Statistiques" do
      attributes_table_for resource do
        row "Nombre d'adresses" do |zone|
          zone.addresses.count
        end
        row "Nombre de commandes" do |zone|
          zone.orders.count
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name, label: "Nom de la zone"
      f.input :description, as: :text
      f.input :base_fee, label: "Frais de base", hint: "Frais de livraison de base pour cette zone"
      f.input :is_active, as: :boolean, label: "Zone active"
    end
    f.actions
  end
end
