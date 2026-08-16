ActiveAdmin.register OfficialBrandBanner do
  menu parent: "Page d'accueil", label: "Marques Officielles", priority: 9

  permit_params :home_page_section_id, :name, :link, :position, :image

  controller do
    def new
      @official_brand_banner = OfficialBrandBanner.new
      if params[:official_brand_banner] && params[:official_brand_banner][:home_page_section_id]
        @official_brand_banner.home_page_section_id = params[:official_brand_banner][:home_page_section_id]
      end
      super
    end
  end

  actions :all, except: []

  filter :home_page_section
  filter :name
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :name
    column "Logo" do |banner|
      if banner.image.attached?
        image_tag(url_for(banner.image), style: "width: 80px; height: 60px; object-fit: contain;")
      else
        "Pas d'image"
      end
    end
    column :link
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
      row :name
      row("Logo") do |banner|
        if banner.image.attached?
          image_tag(url_for(banner.image), style: "max-width: 400px; max-height: 300px; object-fit: contain; border-radius: 8px;")
        else
          "Pas d'image"
        end
      end
      row :link
      row :position
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Boutique Officielle" do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "official_brands"),
              hint: "Sélectionner la section 'Boutiques officielles'."
      f.input :name,
              label: "Nom de la marque",
              hint: "Ex: Samsung, Hisense, Sharp",
              input_html: { placeholder: "Samsung" }
      f.input :image,
              as: :file,
              label: "Logo de la marque",
              hint: f.object.image.attached? ?
                image_tag(url_for(f.object.image), style: "max-width: 200px; margin-top: 10px; border-radius: 4px;") :
                "Taille recommandée : 150x120px. Format : PNG (transparent de préférence)"
      f.input :link,
              label: "Lien URL",
              hint: "Lien vers la boutique ou la page de la marque (Ex: /fr/boutiques/samsung)",
              input_html: { placeholder: "/fr/boutiques/officielles" }
      f.input :position,
              label: "Position",
              hint: "Ordre d'affichage dans le carousel (plus petit = plus à gauche)"
    end
    f.actions
  end
end
