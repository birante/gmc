ActiveAdmin.register ProductCategory do
  menu parent: "Catalogue", priority: 2, label: "Catégories"

  # Specify parameters which should be permitted for assignment
  permit_params :name, :description, :is_active, :position, :icon

  # or consider:
  #
  # permit_params do
  #   permitted = [:name, :slug, :description, :is_active, :position]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Configure ActiveAdmin to use FriendlyId for finding resources
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :name
  filter :description
  filter :is_active
  filter :created_at
  filter :updated_at
  filter :position

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column "Icône" do |category|
      if category.icon.attached?
        image_tag category.icon, style: "max-width: 50px; max-height: 50px; border-radius: 4px;", alt: category.name
      else
        "—"
      end
    end
    column :name
    column :description
    column :is_active
    column :created_at
    column :updated_at
    column :position
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :name
      row :description
      row :is_active
      row :created_at
      row :updated_at
      row :position
    end

    panel "🔗 Lien Public de la Catégorie" do
      div data: { controller: "copy-link" } do
        div style: "display: flex; gap: 10px; margin-bottom: 15px;" do
          input type: "text",
                style: "flex: 1; padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; background: #f9f9f9; font-size: 13px;",
                value: resource.public_url,
                readonly: true,
                data: { "copy-link-target": "input" }

          button type: "button",
                  style: "padding: 8px 16px; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500;",
                  data: { "copy-link-target": "button", action: "copy-link#copy" } do
            "Copier"
          end

          a href: resource.public_url,
            target: "_blank",
            rel: "noopener noreferrer",
            style: "padding: 8px 16px; background: #e5e7eb; color: #374151; text-decoration: none; border-radius: 4px; font-size: 13px; font-weight: 500; display: inline-block;",
            title: "Ouvrir dans un nouvel onglet" do
            "Ouvrir ↗"
          end
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name
      f.input :description
      f.input :is_active
      f.input :position
    f.input :icon, as: :file, label: "Icône de la catégorie", hint: "Taille recommandée : 200×200px (carré). PNG avec fond transparent de préférence. Affiché en cercle (48px–160px selon les pages). Taille max : 5MB."
    end
    f.actions
  end
end
