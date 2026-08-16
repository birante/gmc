# frozen_string_literal: true

ActiveAdmin.register HomePageSectionItem do
  menu parent: "Page d'accueil", label: "Items de section", priority: 11

  permit_params :home_page_section_id, :title, :link, :position, :is_active, :image

  actions :all, except: []

  filter :home_page_section
  filter :title
  filter :is_active
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section
    column :title
    column :link
    column :position
    column "Actif" do |item|
      status_tag(item.is_active? ? "Oui" : "Non", class: item.is_active? ? "ok" : "error")
    end
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Item de section" do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "categories"),
              hint: "Choisir la section 'categories'."
      f.input :title, label: "Titre", hint: "Ex: Électronique, Maison & Déco"
      f.input :link, label: "Lien", hint: "Ex: /fr/categories/electronique"
      f.input :position, label: "Ordre d'affichage", hint: "1 = premier, 2 = second, etc."
      f.input :is_active, label: "Actif"
      f.input :image, as: :file, label: "Image de la catégorie", hint: f.object.image.attached? ? image_tag(f.object.image, style: "max-width: 120px; margin-top: 10px;") : "Taille recommandée : 250×250px (carré). Affiché en cercle de 104px–124px. Format : JPG, PNG."
    end

    f.actions
  end
end
