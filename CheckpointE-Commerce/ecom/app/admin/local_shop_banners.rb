ActiveAdmin.register LocalShopBanner do
  menu parent: "Page d'accueil", label: "Boutiques Locales", priority: 8

  permit_params :home_page_section_id, :name, :slug, :link, :position, :image, :active

  controller do
    def new
      @local_shop_banner = LocalShopBanner.new
      if params[:local_shop_banner] && params[:local_shop_banner][:home_page_section_id]
        @local_shop_banner.home_page_section_id = params[:local_shop_banner][:home_page_section_id]
      end
      super
    end
  end

  actions :all, except: []

  filter :home_page_section
  filter :name
  filter :slug
  filter :position
  filter :active
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :name
    column :slug
    column :link
    column :position
    column :active do |banner|
      status_tag(banner.active? ? "Actif" : "Inactif", class: banner.active? ? "ok" : "error")
    end
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
      row :slug
      row :link
      row :position
      row :active do |banner|
        status_tag(banner.active? ? "Actif" : "Inactif", class: banner.active? ? "ok" : "error")
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de la bannière boutique locale" do
      f.input :home_page_section, collection: HomePageSection.where(section_type: "local_shops")
      f.input :image, as: :file, label: "Logo / Image de la boutique", hint: f.object.image.present? ? image_tag(f.object.image, style: "max-width: 200px; margin-top: 10px;") : "Taille recommandée : 172×172px (carré). Format : JPG, PNG. L'image sera affichée avec des coins arrondis."
      f.input :name
      f.input :slug
      f.input :link
      f.input :position
      f.input :active, label: "Actif", hint: "Décocher pour cacher cette bannière sur la page d'accueil sans la supprimer."
    end
    f.actions
  end
end
