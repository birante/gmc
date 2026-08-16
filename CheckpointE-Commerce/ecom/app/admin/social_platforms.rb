ActiveAdmin.register SocialPlatform do
  menu parent: "Paramètres Système", priority: 3, label: "Plateformes Sociales"
  # Specify parameters which should be permitted for assignment
  permit_params :code, :name, :icon_class, :is_active, :position

  # or consider:
  #
  # permit_params do
  #   permitted = [:code, :name, :icon_class, :is_active, :position]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :code
  filter :name
  filter :icon_class
  filter :is_active
  filter :position
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :code
    column :name
    column :icon_class
    column :is_active
    column :position
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :code
      row :name
      row :icon_class
      row :is_active
      row :position
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :code
      f.input :name
      f.input :icon_class
      f.input :is_active
      f.input :position
    end
    f.actions
  end
end
