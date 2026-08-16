ActiveAdmin.register BlogPost do
  menu parent: "Blog", priority: 1, label: "Articles"

  permit_params :title, :excerpt, :content, :author_name, :status,
                :published_at, :blog_category_id, :cover_image

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end

    def scoped_collection
      super.includes(:blog_category, cover_image_attachment: :blob)
    end
  end

  member_action :purge_cover_image, method: :delete do
    resource.cover_image.purge
    redirect_to edit_admin_blog_post_path(resource), notice: "Image de couverture supprimée."
  end

  scope :all, default: true
  scope("Publiés") { |s| s.where(status: "published") }
  scope("Brouillons") { |s| s.where(status: "draft") }

  filter :title
  filter :blog_category
  filter :status, as: :select, collection: BlogPost::STATUSES.map { |s| [ s.humanize, s ] }
  filter :published_at
  filter :created_at

  index do
    selectable_column
    id_column
    column "Image" do |post|
      if post.cover_image.attached?
        image_tag(post.cover_image, style: "max-width: 80px; height: auto;")
      end
    end
    column :title
    column :blog_category
    column :status do |post|
      status_tag(post.status, class: post.published? ? "ok" : "warning")
    end
    column :published_at
    column :views_count
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :slug
      row :blog_category
      row :author_name
      row :status do |post|
        status_tag(post.status, class: post.published? ? "ok" : "warning")
      end
      row :published_at
      row :excerpt
      row :cover_image do |post|
        if post.cover_image.attached?
          image_tag(post.cover_image, style: "max-width: 480px; height: auto;")
        end
      end
      row :content do |post|
        post.content
      end
      row :views_count
      row :reading_time_minutes do |post|
        "#{post.reading_time_minutes} min"
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Article" do
      f.input :title, label: "Titre", hint: "Ex: Comment vendre plus facilement en ligne au Sénégal"
      f.input :blog_category, label: "Catégorie",
              collection: BlogCategory.ordered,
              include_blank: "— Aucune —"
      f.input :author_name, label: "Auteur", hint: "Ex: Équipe aa"
      f.input :status, as: :select, label: "Statut",
              collection: BlogPost::STATUSES.map { |s| [ s.humanize, s ] },
              include_blank: false
      f.input :published_at, as: :datetime_picker, label: "Date de publication",
              hint: "Laissé vide : sera renseigné automatiquement lors de la publication."
    end

    f.inputs "Image de couverture" do
      cover_hint =
        if f.object.persisted? && f.object.cover_image.attached?
          f.template.content_tag(:span) do
            f.template.image_tag(f.object.cover_image, style: "max-width: 240px; display: block; margin-bottom: 6px;") +
              f.template.link_to("✕ Retirer l'image",
                f.template.purge_cover_image_admin_blog_post_path(f.object),
                method: :delete,
                data: { confirm: "Supprimer cette image ?" },
                style: "color: #c0392b; font-size: 12px;")
          end
        else
          "Format conseillé : 1200×800px"
        end

      f.input :cover_image, as: :file, label: "Image de couverture", hint: cover_hint
    end

    f.inputs "Contenu" do
      f.input :excerpt, label: "Extrait / chapô", as: :text,
              input_html: { rows: 3, maxlength: 300 },
              hint: "Résumé court affiché dans la liste et en SEO (max 300 caractères)"
      f.input :content, label: "Contenu de l'article", as: :rich_text_area,
              hint: "Éditeur enrichi : gras, italique, listes, titres, liens, images (collées ou déposées)."
    end

    f.actions
  end
end
