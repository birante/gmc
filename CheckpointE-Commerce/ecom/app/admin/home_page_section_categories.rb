ActiveAdmin.register HomePageSectionCategory do
  menu parent: "Page d'accueil", label: "Catégories", priority: 4

  permit_params :home_page_section_id, :product_category_id, :product_sub_category_id, :position

  controller do
    def new
      @home_page_section_category = HomePageSectionCategory.new
      if params[:home_page_section_category] && params[:home_page_section_category][:home_page_section_id]
        @home_page_section_category.home_page_section_id = params[:home_page_section_category][:home_page_section_id]
      end
      super
    end
  end

  actions :all, except: []

  filter :home_page_section
  filter :product_category
  filter :product_sub_category
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :product_category
    column :product_sub_category
    column :position
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section do |category|
        link_to category.home_page_section.title, admin_home_page_section_path(category.home_page_section) if category.home_page_section
      end
      row :product_category do |category|
        link_to category.product_category.name, admin_product_category_path(category.product_category) if category.product_category
      end
      row :product_sub_category do |category|
        link_to category.product_sub_category.name, admin_product_sub_category_path(category.product_sub_category) if category.product_sub_category
      end
      row :position
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de la catégorie" do
      f.input :home_page_section, collection: HomePageSection.where(section_type: "categories")
      f.input :product_category
      f.input :product_sub_category
      f.input :position
    end
    f.actions
  end
end
