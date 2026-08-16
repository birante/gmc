# frozen_string_literal: true

ActiveAdmin.register ShopPageSectionProduct do
  menu parent: "Page Boutique", label: "Produits par section", priority: 3

  permit_params :shop_page_section_id, :item_id, :position, :is_active

  filter :shop_page_section
  filter :item
  filter :is_active
  filter :position
  filter :created_at

  controller do
    def new
      @shop_page_section_product = ShopPageSectionProduct.new
      if params[:shop_page_section_product] && params[:shop_page_section_product][:shop_page_section_id]
        @shop_page_section_product.shop_page_section_id = params[:shop_page_section_product][:shop_page_section_id]
      end
      super
    end

    def scoped_collection
      super.includes(:shop_page_section, :item)
    end
  end

  index do
    selectable_column
    id_column
    column :shop_page_section
    column :item
    column :position
    column :is_active do |sp|
      status_tag sp.is_active? ? "Actif" : "Inactif", class: sp.is_active? ? "ok" : "error"
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :shop_page_section
      row :item
      row :position
      row :is_active do |sp|
        status_tag sp.is_active? ? "Actif" : "Inactif", class: sp.is_active? ? "ok" : "error"
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop_page_section
      if f.object.shop_page_section
        f.input :item,
                as: :select,
                collection: f.object.shop_page_section.shop.available_items.includes(:variants).map { |i| [ "#{i.name} (#{i.id})", i.id ] },
                hint: "Uniquement les produits de la boutique"
      else
        f.input :item
      end
      f.input :position
      f.input :is_active
    end
    f.actions
  end
end
