ActiveAdmin.register HeroSliderSlide do
  menu parent: "Page d'accueil", label: "Slides Hero", priority: 2

  permit_params :home_page_section_id, :badge_text, :badge_bg_color, :badge_text_color, :title, :cta_text, :cta_link, :gradient, :position, :image, :image_tablet, :image_mobile

  member_action :purge_image_mobile, method: :delete do
    resource.image_mobile.purge
    redirect_to admin_hero_slider_slide_path(resource), notice: "Image mobile supprimée."
  end

  member_action :purge_image_tablet, method: :delete do
    resource.image_tablet.purge
    redirect_to admin_hero_slider_slide_path(resource), notice: "Image tablette supprimée."
  end

  controller do
    def new
      @hero_slider_slide = HeroSliderSlide.new
      if params[:hero_slider_slide] && params[:hero_slider_slide][:home_page_section_id]
        @hero_slider_slide.home_page_section_id = params[:hero_slider_slide][:home_page_section_id]
      end
      super
    end

    def scoped_collection
      super.includes(:home_page_section, image_attachment: :blob, image_tablet_attachment: :blob, image_mobile_attachment: :blob)
    end
  end

  actions :all, except: []

  filter :home_page_section
  filter :title
  filter :badge_text
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :image do |slide|
      image_tag(slide.image, style: "max-width: 100px; height: auto;") if slide.image.present?
    end
    column :image_tablet do |slide|
      image_tag(slide.image_tablet, style: "max-width: 100px; height: auto;") if slide.image_tablet.present?
    end
    column :image_mobile do |slide|
      image_tag(slide.image_mobile, style: "max-width: 100px; height: auto;") if slide.image_mobile.present?
    end
    column :title
    column :badge_text
    column :cta_text
    column :position
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section do |slide|
        link_to slide.home_page_section.title, admin_home_page_section_path(slide.home_page_section) if slide.home_page_section
      end
      row :image do |slide|
        image_tag(slide.image, style: "max-width: 400px; height: auto;") if slide.image.present?
      end
      row :image_tablet do |slide|
        image_tag(slide.image_tablet, style: "max-width: 360px; height: auto;") if slide.image_tablet.present?
      end
      row :image_mobile do |slide|
        image_tag(slide.image_mobile, style: "max-width: 320px; height: auto;") if slide.image_mobile.present?
      end
      row :badge_text
      row :badge_bg_color
      row :badge_text_color
      row :title
      row :cta_text
      row :cta_link
      row :gradient
      row :position
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Slide Hero" do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "hero_slider"),
              hint: "Laisser par défaut si vous n'avez qu'une seule section Hero."

      f.input :position,
              label: "Ordre d'affichage",
              hint: "1 = premier slide, 2 = second, etc."

      f.input :image,
              as: :file,
              label: "Image Desktop (≥ 1024px)",
              hint: f.object.image.present? ? image_tag(f.object.image, style: "max-width: 200px; margin-top: 10px;") : "Desktop recommandé : 1280×560px (minimum 1166×350px). JPG, PNG ou WebP."

      if f.object.image_tablet.present?
        f.template.concat(
          f.template.content_tag(:li) do
            f.template.content_tag(:label, "Image tablette actuelle") +
            f.template.content_tag(:div) do
              f.template.image_tag(f.object.image_tablet, style: "max-width: 200px; margin-top: 10px; display: block;") +
              f.template.link_to("Supprimer l'image tablette", purge_image_tablet_admin_hero_slider_slide_path(f.object), method: :delete, data: { confirm: "Supprimer cette image tablette ?" }, class: "button")
            end
          end
        )
      end

      f.input :image_tablet,
              as: :file,
              label: "Image Tablette (768–1023px, optionnelle)",
              hint: "Tablette recommandé : 1024×450px. Si absente, l'image desktop est utilisée en fallback."

      if f.object.image_mobile.present?
        f.template.concat(
          f.template.content_tag(:li) do
            f.template.content_tag(:label, "Image mobile actuelle") +
            f.template.content_tag(:div) do
              f.template.image_tag(f.object.image_mobile, style: "max-width: 200px; margin-top: 10px; display: block;") +
              f.template.link_to("Supprimer l'image mobile", purge_image_mobile_admin_hero_slider_slide_path(f.object), method: :delete, data: { confirm: "Supprimer cette image mobile ?" }, class: "button")
            end
          end
        )
      end

      f.input :image_mobile,
              as: :file,
              label: "Image Mobile (< 768px, optionnelle)",
              hint: "Mobile recommandé : 768×350px (minimum 750×400px). Si absente, l'image tablette ou desktop est utilisée en fallback."
    end

    f.inputs "Contenu" do
      f.input :badge_text, label: "Badge - Texte", hint: "Ex: Promo, Nouveau, -30%"
      f.input :badge_bg_color, as: :string, label: "Badge - Couleur de fond", hint: "Ex: bg-red-600, bg-yellow-500"
      f.input :badge_text_color, as: :string, label: "Badge - Couleur du texte", hint: "Ex: text-white, text-black"
      f.input :title, label: "Titre principal", hint: "Ex: Découvrez nos nouveautés du moment"
      f.input :cta_text, label: "Bouton - Texte", hint: "Ex: Découvrir, Profiter, Acheter"
      f.input :cta_link, label: "Bouton - Lien", hint: "Ex: /fr/produits, /fr/categories/electronique, https://aa.com/promo"
    end

    f.inputs "Style" do
      f.input :gradient, label: "Dégradé de fond", hint: "Ex: from-[#B794F4] via-[#9F7AEA] to-[#805AD5] ou from-purple-600 to-blue-600"
    end

    f.actions
  end
end
