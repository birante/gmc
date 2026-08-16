ActiveAdmin.register ShopContact do
  menu parent: "Boutiques & Vendeurs", priority: 4, label: "Contacts Boutique"
  # Specify parameters which should be permitted for assignment
  permit_params :shop_id, :country_code, :phone_number, :is_whatsapp

  # or consider:
  #
  # permit_params do
  #   permitted = [:shop_id, :country_code, :phone_number, :is_whatsapp]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :shop
  filter :country_code
  filter :phone_number
  filter :is_whatsapp
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :shop
    column :country_code
    column :phone_number
    column :is_whatsapp
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :shop
      row :country_code
      row :phone_number
      row :is_whatsapp
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop
      f.input :country_code
      f.input :phone_number
      f.input :is_whatsapp
    end
    f.actions
  end
end
