ActiveAdmin.register Address do
  menu parent: "Utilisateurs", priority: 4, label: "Adresses"
  # Specify parameters which should be permitted for assignment
  permit_params :user_id, :delivery_zone_id, :street_address, :city, :postal_code,
                :country, :additional_info, :is_default, :latitude, :longitude

  # For security, limit the actions that should be available
  actions :all

  # Configure ActiveAdmin to use FriendlyId for finding resources
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :user
  filter :delivery_zone
  filter :street_address
  filter :city
  filter :postal_code
  filter :country
  filter :is_default, as: :select, collection: { "Par défaut" => true, "Secondaire" => false }
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :user do |address|
      link_to address.user.full_name, admin_user_path(address.user) if address.user
    end
    column :street_address
    column :city
    column :postal_code
    column :country
    column :delivery_zone
    column :is_default do |address|
      if address.is_default
        status_tag("Oui", class: "ok")
      else
        status_tag("Non")
      end
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :user do |address|
        link_to address.user.full_name, admin_user_path(address.user) if address.user
      end
      row :street_address
      row :city
      row :postal_code
      row :country
      row :additional_info
      row :delivery_zone
      row :is_default do |address|
        if address.is_default
          status_tag("Oui", class: "ok")
        else
          status_tag("Non")
        end
      end
      row :latitude
      row :longitude
      row "URL Slug (read-only)" do
        resource.slug
      end
      row :created_at
      row :updated_at
    end

    if resource.latitude.present? && resource.longitude.present?
      panel "Localisation" do
        div do
          "Coordonnées GPS: #{resource.latitude}, #{resource.longitude}"
        end
        div do
          link_to "Voir sur Google Maps",
                  "https://www.google.com/maps?q=#{resource.latitude},#{resource.longitude}",
                  target: "_blank",
                  class: "button"
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de l'adresse" do
      f.input :user
      f.input :street_address, label: "Adresse", as: :text
      f.input :city, label: "Ville"
      f.input :postal_code, label: "Code postal"
      f.input :country, label: "Pays"
      f.input :additional_info, label: "Informations complémentaires", as: :text
      f.input :delivery_zone, label: "Zone de livraison"
      f.input :is_default, as: :boolean, label: "Adresse par défaut"
    end

    f.inputs "Géolocalisation (optionnel)" do
      f.input :latitude
      f.input :longitude
    end

    f.actions
  end
end
