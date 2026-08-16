ActiveAdmin.register ShopLegalInfo do
  menu parent: "Boutiques & Vendeurs", priority: 5, label: "Informations Légales"
  # Specify parameters which should be permitted for assignment
  permit_params :shop_id, :legal_form, :rc_number, :ninea_number

  # or consider:
  #
  # permit_params do
  #   permitted = [:shop_id, :legal_form, :rc_number, :ninea_number]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :shop
  filter :legal_form
  filter :rc_number
  filter :ninea_number
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :shop
    column :legal_form
    column :rc_number
    column :ninea_number
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :shop
      row :legal_form
      row :rc_number
      row :ninea_number
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop
      f.input :legal_form
      f.input :rc_number
      f.input :ninea_number
    end
    f.actions
  end
end
