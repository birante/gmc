# frozen_string_literal: true

ActiveAdmin.register ShopPageSection do
  menu parent: "Page Boutique", label: "Sections", priority: 2

  config.sort_order = "position_asc"

  permit_params :shop_id, :section_type, :title, :description, :position, :is_active

  filter :shop
  filter :section_type, as: :select, collection: -> { ShopPageSection::SECTION_TYPES }
  filter :title
  filter :is_active
  filter :position
  filter :created_at

  scope :all, default: true
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  controller do
    def scoped_collection
      super.includes(:shop).order(:position)
    end
  end

  index do
    selectable_column
    id_column
    column :shop
    column :section_type
    column :title
    column :is_active do |section|
      status_tag section.is_active? ? "Actif" : "Inactif", class: section.is_active? ? "ok" : "error"
    end
    column :position
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :shop
      row :section_type
      row :title
      row :description
      row :is_active do |section|
        status_tag section.is_active? ? "Actif" : "Inactif", class: section.is_active? ? "ok" : "error"
      end
      row :position
      row :created_at
      row :updated_at
    end

    panel "Produits sélectionnés" do
      div do
        link_to "Ajouter un produit",
                new_admin_shop_page_section_product_path(shop_page_section_product: { shop_page_section_id: resource.id }),
                class: "button"
      end
      if resource.shop_page_section_products.any?
        table_for resource.shop_page_section_products.ordered.includes(:item) do
          column :position
          column "Produit", &:item
          column :is_active do |sp|
            status_tag sp.is_active? ? "Actif" : "Inactif", class: sp.is_active? ? "ok" : "error"
          end
          column "Actions" do |sp|
            link_to "Modifier", edit_admin_shop_page_section_product_path(sp), class: "member_link view_link"
          end
        end
      else
        para "Aucun produit. Les sections hero_carousel, global_carousels, etc. peuvent afficher des produits sélectionnés.", style: "color: #666; font-style: italic;"
      end
    end

    panel "Catégories (Explorer par catégorie)" do
      div do
        link_to "Ajouter une catégorie",
                new_admin_shop_page_section_category_path(shop_page_section_category: { shop_page_section_id: resource.id }),
                class: "button"
      end
      if resource.shop_page_section_categories.any?
        table_for resource.shop_page_section_categories.ordered.includes(:product_sub_category) do
          column :position
          column "Catégorie", &:product_sub_category
          column "Actions" do |sc|
            link_to "Modifier", edit_admin_shop_page_section_category_path(sc), class: "member_link view_link"
          end
        end
      else
        para "Aucune catégorie. Pour la section 'Explorer par catégorie', ajoutez des catégories dans l'ordre souhaité.", style: "color: #666; font-style: italic;"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Section de la page boutique" do
      f.input :shop
      f.input :section_type, as: :select, collection: ShopPageSection::SECTION_TYPES.map { |t| [ t.humanize, t ] }
      f.input :title
      f.input :description, as: :text
      f.input :position
      f.input :is_active
    end
    f.actions
  end
end
