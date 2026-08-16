ActiveAdmin.register SecondaryBanner do
  menu parent: "Page d'accueil", label: "Bannières Secondaires", priority: 5

  permit_params :home_page_section_id, :title, :link, :gradient_from, :gradient_to, :position_type, :position_order, :image, :image_mobile

  controller do
    def new
      @secondary_banner = SecondaryBanner.new
      if params[:secondary_banner] && params[:secondary_banner][:home_page_section_id]
        @secondary_banner.home_page_section_id = params[:secondary_banner][:home_page_section_id]
      end
      super
    end
  end

  actions :all, except: []

  member_action :purge_image_mobile, method: :delete do
    resource.image_mobile.purge
    redirect_to edit_admin_secondary_banner_path(resource), notice: "Image mobile supprimée."
  end

  filter :home_page_section
  filter :title
  filter :position_type, as: :select, collection: -> { SecondaryBanner.distinct.pluck(:position_type).compact }
  filter :position_order
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :title
    column :image do |banner|
      image_tag(banner.image, style: "max-width: 100px; height: auto;") if banner.image.attached?
    end
    column :image_mobile do |banner|
      image_tag(banner.image_mobile, style: "max-width: 100px; height: auto;") if banner.image_mobile.attached?
    end
    column :link
    column :position_type
    column :position_order
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section do |banner|
        link_to banner.home_page_section.title, admin_home_page_section_path(banner.home_page_section) if banner.home_page_section
      end
      row :title
      row :link
      row :gradient_from
      row :gradient_to
      row :position_type
      row :position_order
      row :image do |banner|
        image_tag(banner.image, style: "max-width: 320px; height: auto;") if banner.image.attached?
      end
      row :image_mobile do |banner|
        image_tag(banner.image_mobile, style: "max-width: 320px; height: auto;") if banner.image_mobile.attached?
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
      f.inputs "Bannière secondaire (1 sur 5)" do
        f.input :home_page_section,
          label: "Section",
          collection: HomePageSection.where(section_type: "secondary_banners"),
          hint: "Laisser par défaut si vous n'avez qu'une seule section."

        f.input :position_order,
          label: "Ordre d'affichage",
          hint: "Utiliser 1 à 5 pour remplir la grille (5 éléments requis)."

        f.input :title,
          label: "Titre",
          hint: "Ex: Smartphones & Tablettes, Gaming, Électroménager"

        f.input :link,
          label: "Lien",
          hint: "Ex: /fr/categories/electronique ou /fr/produits"
      end

      f.inputs "Visuel" do
        image_hint =
          if f.object.image.attached?
            f.template.content_tag(:span) do
              f.template.image_tag(f.object.image, style: "max-width: 200px; margin-top: 10px; display: block;")
            end
          else
            "Si vide, le dégradé sera utilisé. Format conseillé : 1200×700"
          end

        image_mobile_hint =
          if f.object.image_mobile.attached?
            f.template.content_tag(:span) do
              f.template.image_tag(f.object.image_mobile, style: "max-width: 200px; margin-top: 10px; margin-bottom: 6px; display: block;") +
              f.template.link_to("Supprimer l'image mobile",
                f.template.purge_image_mobile_admin_secondary_banner_path(f.object),
                method: :delete,
                data: { confirm: "Supprimer cette image mobile ?" },
                style: "color: #c0392b; font-size: 12px;"
              )
            end
          else
            "Optionnel. Si vide, l'image desktop sera utilisée sur mobile. Format conseillé : 800×480"
          end

        f.input :image,
          as: :file,
          label: "Image (optionnelle)",
          hint: image_hint

        f.input :image_mobile,
          as: :file,
          label: "Image mobile (optionnelle)",
          hint: image_mobile_hint

        f.input :gradient_from,
          label: "Dégradé - Couleur 1",
          hint: "Ex: #1E3A5F"

        f.input :gradient_to,
          label: "Dégradé - Couleur 2",
          hint: "Ex: #0F172A"
      end

      f.inputs "Disposition" do
        f.input :position_type,
          label: "Type de position",
          hint: "Optionnel, pour le tri interne si besoin."
      end

    f.actions
  end
end
