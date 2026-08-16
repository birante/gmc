# frozen_string_literal: true

ActiveAdmin.register ShopPageHeader do
  menu false # Remplacé par ShopPageHeaderSlide (plusieurs slides possibles)

  permit_params :shop_id, :link, :button_text, :image

  filter :shop
  filter :button_text
  filter :created_at

  index do
    selectable_column
    id_column
    column :shop
    column "Image" do |header|
      if header.image.attached?
        image_tag header.image, style: "max-width: 80px; max-height: 50px; border-radius: 4px;", alt: "Header"
      else
        "—"
      end
    end
    column :link
    column :button_text
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :shop
      row :link
      row :button_text
      row "Image" do |header|
        if header.image.attached?
          image_tag url_for(header.image), style: "max-width: 400px; max-height: 200px; border-radius: 8px;", alt: "Header"
        else
          "Aucune image"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Header de la page boutique" do
      f.input :shop, hint: "Une seule configuration par boutique"
      f.input :image, as: :file, hint: "Photo de fond du header. Taille recommandée : 1200×420px. Format : JPG, PNG. L'image est affichée en pleine largeur (object-cover)."
      f.input :link, hint: "URL du lien (ex: /fr/produits, #products-section)"
      f.input :button_text, hint: "Texte du bouton (ex: Découvrir, Voir les offres)"
    end
    f.actions
  end
end
