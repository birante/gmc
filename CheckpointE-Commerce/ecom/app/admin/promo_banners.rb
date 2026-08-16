ActiveAdmin.register PromoBanner do
  menu parent: "Page d'accueil", label: "Bannières Promo", priority: 3

  permit_params :home_page_section_id, :title, :cta_text, :cta_link, :position, :image, :image_mobile, :overlay_image

  controller do
    def new
      @promo_banner = PromoBanner.new
      if params[:promo_banner] && params[:promo_banner][:home_page_section_id]
        @promo_banner.home_page_section_id = params[:promo_banner][:home_page_section_id]
      end
      super
    end

    def scoped_collection
      super.includes(:home_page_section)
    end
  end

  actions :all, except: []

  member_action :purge_image, method: :delete do
    resource.image.purge
    redirect_to edit_admin_promo_banner_path(resource), notice: "Image supprimée."
  end

  member_action :purge_image_mobile, method: :delete do
    resource.image_mobile.purge
    redirect_to edit_admin_promo_banner_path(resource), notice: "Image mobile supprimée."
  end

  member_action :purge_overlay_image, method: :delete do
    resource.overlay_image.purge
    redirect_to edit_admin_promo_banner_path(resource), notice: "Image overlay supprimée."
  end

  filter :home_page_section
  filter :title
  filter :position
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
    column :cta_text
    column :cta_link
    column :position
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
      row :cta_text
      row :cta_link
      row :position
      row :image do |banner|
        image_tag(banner.image, style: "max-width: 320px; height: auto;") if banner.image.attached?
      end
      row :image_mobile do |banner|
        image_tag(banner.image_mobile, style: "max-width: 320px; height: auto;") if banner.image_mobile.attached?
      end
      row :overlay_image do |banner|
        image_tag(banner.overlay_image, style: "max-width: 200px; height: auto;") if banner.overlay_image.attached?
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Bannière promo" do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "promo_banners"),
              hint: "Laisser par défaut si vous n'avez qu'une seule section."

      f.input :position,
              label: "Ordre d'affichage",
              hint: "1 = première bannière, 2 = seconde, etc."

            image_hint =
              if f.object.persisted? && f.object.image.attached?
                f.template.content_tag(:span) do
                  f.template.image_tag(f.object.image, style: "max-width: 200px; display: block; margin-bottom: 6px;") +
                  f.template.link_to("✕ Retirer l'image",
                    f.template.purge_image_admin_promo_banner_path(f.object),
                    method: :delete,
                    data: { confirm: "Supprimer cette image ?" },
                    style: "color: #c0392b; font-size: 12px;"
                  )
                end
              else
                "Format conseillé : 600×430px"
              end

            image_mobile_hint =
              if f.object.persisted? && f.object.image_mobile.attached?
                f.template.content_tag(:span) do
                  f.template.image_tag(f.object.image_mobile, style: "max-width: 200px; display: block; margin-bottom: 6px;") +
                  f.template.link_to("✕ Retirer l'image mobile",
                    f.template.purge_image_mobile_admin_promo_banner_path(f.object),
                    method: :delete,
                    data: { confirm: "Supprimer cette image mobile ?" },
                    style: "color: #c0392b; font-size: 12px;"
                  )
                end
              else
                "Optionnel. Si vide, l'image desktop sera utilisée sur mobile. Format conseillé : 600×430px"
              end

            overlay_hint =
              if f.object.persisted? && f.object.overlay_image.attached?
                f.template.content_tag(:span) do
                  f.template.image_tag(f.object.overlay_image, style: "max-width: 120px; display: block; margin-bottom: 6px;") +
                  f.template.link_to("✕ Retirer l'image overlay",
                    f.template.purge_overlay_image_admin_promo_banner_path(f.object),
                    method: :delete,
                    data: { confirm: "Supprimer cette image overlay ?" },
                    style: "color: #c0392b; font-size: 12px;"
                  )
                end
              else
                "Ex : visuel produit transparent"
              end

            f.input :image, as: :file, label: "Image (obligatoire)", hint: image_hint
      f.input :image_mobile, as: :file, label: "Image mobile (optionnelle)", hint: image_mobile_hint
            f.input :overlay_image, as: :file, label: "Image overlay (optionnelle)", hint: overlay_hint
    end

    f.inputs "Contenu" do
      f.input :title, label: "Titre", hint: "Ex: Électronique, Maison & Déco"
      f.input :cta_text, label: "Bouton - Texte", hint: "Ex: Voir, Découvrir, Acheter"
      f.input :cta_link, label: "Bouton - Lien", hint: "Ex: /fr/categories/electronique"
    end

    f.actions
  end
end
