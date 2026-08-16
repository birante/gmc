# frozen_string_literal: true

ActiveAdmin.register HomePageSectionProduct do
  menu parent: "Page d'accueil", label: "Made in Senegal (Produits)", priority: 10

  permit_params :home_page_section_id, :item_id, :position, :is_active

  actions :all, except: []

  filter :home_page_section
  filter :item
  filter :is_active
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column "Produit" do |product|
      link_to product.item.name, admin_item_path(product.item) if product.item
    end
    column "Boutique" do |product|
      product.item&.shop&.name
    end
    column :position
    column "Actif" do |product|
      status_tag(product.is_active? ? "Oui" : "Non", class: product.is_active? ? "ok" : "error")
    end
    column "Image" do |product|
      if product.item&.has_image?
        storage_image_tag(product.item.display_image, variant_name: :thumbnail, alt: product.item.name, style: "width: 50px; height: 50px; object-fit: cover;")
      else
        "Pas d'image"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section
      row("Produit") { |product| link_to product.item.name, admin_item_path(product.item) if product.item }
      row("Boutique") { |product| product.item&.shop&.name }
      row :position
      row("Actif") { |product| product.is_active? ? "Oui" : "Non" }
      row("Image") do |product|
        if product.item&.has_image?
          storage_image_tag(product.item.display_image, variant_name: :card, alt: product.item.name, style: "max-width: 300px; max-height: 300px;")
        else
          "Pas d'image"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs ("Made in Senegal (Produit)") do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "local_shops"),
              hint: "Choisir la section 'local_shops' (Boutiques Locales / Made in Senegal)."
      f.input :item,
              label: "Produit",
              as: :select,
              collection: Item.available_for_sale
                              .includes(:shop, :currency, :variants)
                              .order("items.name ASC")
                              .map { |item| [ "#{item.name} - #{item.shop&.name}", item.id ] },
              input_html: { class: "select2" },
              hint: "Sélectionner un produit disponible à la vente. Privilégiez les produits Made in Senegal."
      f.input :position, label: "Position (1-6)", hint: "Position d'affichage (1 à 6)"
      f.input :is_active, label: "Actif"
    end

    f.actions
  end
end
