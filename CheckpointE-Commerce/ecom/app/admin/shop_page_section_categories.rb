# frozen_string_literal: true

ActiveAdmin.register ShopPageSectionCategory do
  menu parent: "Page Boutique", label: "Catégories par section", priority: 4

  permit_params :shop_page_section_id, :product_sub_category_id, :position

  filter :shop_page_section
  filter :product_sub_category
  filter :position
  filter :created_at

  controller do
    def new
      @shop_page_section_category = ShopPageSectionCategory.new
      if params[:shop_page_section_category] && params[:shop_page_section_category][:shop_page_section_id]
        @shop_page_section_category.shop_page_section_id = params[:shop_page_section_category][:shop_page_section_id]
      end
      super
    end

    def scoped_collection
      super.includes(:shop_page_section, :product_sub_category)
    end
  end

  index do
    selectable_column
    id_column
    column :shop_page_section
    column :product_sub_category
    column :position
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :shop_page_section
      row :product_sub_category
      row :position
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop_page_section
      f.input :product_sub_category, as: :select, collection: ProductSubCategory.where(is_active: true).order(:name).map { |c| [ "#{c.name} (#{c.product_category&.name})", c.id ] }
      f.input :position, hint: "Ordre d'affichage (1, 2, 3...). Les espaces sont respectés."
    end
    f.actions
  end
end
