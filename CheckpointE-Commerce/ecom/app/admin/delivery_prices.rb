ActiveAdmin.register DeliveryPrice do
  menu parent: "Logistique", priority: 3, label: "Prix de Livraison"
  # Specify parameters which should be permitted for assignment
  permit_params :delivery_zone_id, :delivery_category_id, :price

  # For security, limit the actions that should be available
  actions :all

  # Add or remove filters to toggle their visibility
  filter :id
  filter :delivery_zone
  filter :delivery_category
  filter :price
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :delivery_zone do |dp|
      link_to dp.delivery_zone&.name, admin_delivery_zone_path(dp.delivery_zone) if dp.delivery_zone
    end
    column :delivery_category do |dp|
      if dp.delivery_category
        "#{dp.delivery_category.name} (#{dp.delivery_category.code})"
      end
    end
    column "Ordre catégorie" do |dp|
      status_tag dp.delivery_category&.display_order, class: "info"
    end
    column :price do |dp|
      number_to_currency(dp.price, unit: "€")
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :delivery_zone do |dp|
        link_to dp.delivery_zone&.name, admin_delivery_zone_path(dp.delivery_zone) if dp.delivery_zone
      end
      row :delivery_category do |dp|
        if dp.delivery_category
          link_to "#{dp.delivery_category.name} (#{dp.delivery_category.code})",
                  admin_delivery_category_path(dp.delivery_category)
        end
      end
      row "Description de la catégorie" do |dp|
        dp.delivery_category&.description
      end
      row "Ordre de la catégorie" do |dp|
        status_tag dp.delivery_category&.display_order, class: "info"
      end
      row :price do |dp|
        number_to_currency(dp.price, unit: "€")
      end
      row :created_at
      row :updated_at
    end

    panel "Informations de la zone" do
      attributes_table_for resource.delivery_zone do
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
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :delivery_zone, label: "Zone de livraison"
      f.input :delivery_category, label: "Catégorie de livraison"
      f.input :price, label: "Prix", hint: "Prix de livraison pour cette zone et cette catégorie"
    end
    f.actions
  end
end
