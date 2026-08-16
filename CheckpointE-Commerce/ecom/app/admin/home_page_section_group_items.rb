# frozen_string_literal: true

ActiveAdmin.register HomePageSectionGroupItem do
  menu parent: "Page d'accueil", label: "Éléments (Tendances)", priority: 7

  permit_params :home_page_section_group_id, :title, :link, :position, :is_active, :image

  actions :all, except: []

  filter :home_page_section_group
  filter :title
  filter :is_active
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :home_page_section_group
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

    f.inputs "Élément du groupe" do
      f.input :home_page_section_group,
              label: "Groupe",
              collection: HomePageSectionGroup.order(:position),
              hint: "Choisir le groupe de tendances."
      f.input :title, label: "Titre", hint: "Ex: Smartphones, Sneakers, Maquillage"
      f.input :link, label: "Lien", hint: "Ex: /fr/produits ou /fr/categories/mode"
      f.input :position, label: "Ordre", hint: "1 à 4 (4 éléments par groupe)"
      f.input :is_active, label: "Actif"
      f.input :image, as: :file, label: "Image de la tendance", hint: f.object.image.attached? ? image_tag(f.object.image, style: "max-width: 120px; margin-top: 10px;") : "Taille recommandée : 400×400px (carré). Affiché en grille 2×2 dans la carte tendances. Format : JPG, PNG."
    end

    f.actions
  end
end
