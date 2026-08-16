ActiveAdmin.register ShopSocialLink do
  menu parent: "Boutiques & Vendeurs", priority: 6, label: "Liens Sociaux"
  # Specify parameters which should be permitted for assignment
  permit_params :shop_id, :social_platform_id, :url

  # or consider:
  #
  # permit_params do
  #   permitted = [:shop_id, :social_platform_id, :url]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :shop
  filter :social_platform
  filter :url
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :shop
    column :social_platform
    column :url
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :shop
      row :social_platform
      row :url
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop
      f.input :social_platform
      f.input :url
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:shop, :social_platform)
    end
  end
end
