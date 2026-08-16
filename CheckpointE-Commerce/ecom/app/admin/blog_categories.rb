ActiveAdmin.register BlogCategory do
  menu parent: "Blog", priority: 2, label: "Catégories"

  permit_params :name, :description, :position, :active

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  filter :name
  filter :active
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :position
    column :active do |cat|
      status_tag(cat.active? ? "Actif" : "Inactif", class: cat.active? ? "ok" : "warning")
    end
    column "Articles" do |cat|
      cat.blog_posts.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :description
      row :position
      row :active
      row :created_at
      row :updated_at
    end

    panel "Articles dans cette catégorie" do
      table_for blog_category.blog_posts.recent do
        column :title do |post|
          link_to post.title, admin_blog_post_path(post)
        end
        column :status
        column :published_at
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Catégorie de blog" do
      f.input :name, label: "Nom", hint: "Ex: Tutos vendeurs, Actualités, Tips e-commerce"
      f.input :description, label: "Description", as: :text, input_html: { rows: 3 }
      f.input :position, label: "Ordre d'affichage", hint: "0 = en premier"
      f.input :active, label: "Visible publiquement"
    end

    f.actions
  end
end
