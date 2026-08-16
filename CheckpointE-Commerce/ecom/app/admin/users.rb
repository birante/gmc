# frozen_string_literal: true

ActiveAdmin.register User do
  menu parent: "Utilisateurs", priority: 1, label: "Clients"

  # Specify parameters which should be permitted for assignment
  permit_params :email_address, :first_name, :last_name, :country_code, :phone_number

  # or consider:
  #
  # permit_params do
  #   permitted = [:email_address, :password_digest, :first_name, :last_name, :country_code, :phone_number]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :email_address
  filter :created_at
  filter :updated_at
  filter :first_name
  filter :last_name
  filter :country_code
  filter :phone_number

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :email_address
    column :created_at
    column :updated_at
    column :first_name
    column :last_name
    column :country_code
    column :phone_number
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :email_address
      row :created_at
      row :updated_at
      row :first_name
      row :last_name
      row :country_code
      row :phone_number
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :email_address
      f.input :first_name
      f.input :last_name
      f.input :country_code
      f.input :phone_number
    end
    f.actions
  end
end
