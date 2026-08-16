ActiveAdmin.register Currency do
  menu parent: "Paramètres Système", priority: 1, label: "Devises"
  # Specify parameters which should be permitted for assignment
  permit_params :code, :symbol, :name, :thousands_separator, :decimal_separator, :symbol_precedes_amount, :is_active

  # or consider:
  #
  # permit_params do
  #   permitted = [:code, :symbol, :name, :thousands_separator, :decimal_separator, :symbol_precedes_amount, :is_active]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :code
  filter :symbol
  filter :name
  filter :thousands_separator
  filter :decimal_separator
  filter :symbol_precedes_amount
  filter :is_active
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :code
    column :symbol
    column :name
    column :thousands_separator
    column :decimal_separator
    column :symbol_precedes_amount
    column :is_active
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :code
      row :symbol
      row :name
      row :thousands_separator
      row :decimal_separator
      row :symbol_precedes_amount
      row :is_active
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :code
      f.input :symbol
      f.input :name
      f.input :thousands_separator
      f.input :decimal_separator
      f.input :symbol_precedes_amount
      f.input :is_active
    end
    f.actions
  end
end
