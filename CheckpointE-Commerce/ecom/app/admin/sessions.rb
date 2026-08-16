# Enregistré sous "UserSession" pour éviter le conflit avec Admin::SessionsController (login admin)
ActiveAdmin.register Session, as: "UserSession" do
  menu parent: "Utilisateurs", priority: 5, label: "Sessions"
  # Specify parameters which should be permitted for assignment
  permit_params :user_id, :ip_address, :user_agent

  # or consider:
  #
  # permit_params do
  #   permitted = [:user_id, :ip_address, :user_agent]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :user
  filter :ip_address
  filter :user_agent
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :user
    column :ip_address
    column :user_agent
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :user
      row :ip_address
      row :user_agent
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :user
      f.input :ip_address
      f.input :user_agent
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:sessionable)
    end
  end
end
