# frozen_string_literal: true

ActiveAdmin.register ShopBanner do
  menu parent: "Boutiques & Vendeurs", priority: 2, label: "Bannières Boutiques"

  permit_params :shop_id, :position, :title, :cta_text, :cta_link, :image

  filter :shop
  filter :title
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column :shop
    column :title
    column :position
    column "Image" do |banner|
      if banner.image.attached?
        image_tag banner.image, style: "max-width: 100px; max-height: 100px; border-radius: 4px;", alt: banner.title
      else
        "—"
      end
    end
    column :cta_text
    column :cta_link
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :shop
      row :position
      row :title
      row :cta_text
      row :cta_link
      row "Image" do |banner|
        if banner.image.attached?
          image_tag url_for(banner.image), style: "max-width: 500px; max-height: 500px; border-radius: 8px;", alt: banner.title
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
    f.inputs do
      f.input :shop
      f.input :position
      f.input :title
      f.input :cta_text, hint: "Texte du bouton d'action (ex: 'Voir', 'Acheter')"
      f.input :cta_link, hint: "Lien vers lequel rediriger (ex: '/fr/produits')"
      f.input :image, as: :file, hint: "Taille recommandée : 1200×400px (pleine largeur). Format : JPG, PNG, SVG."

      if f.object.image.attached?
        f.inputs "Image actuelle" do
          div do
            image_tag url_for(f.object.image), style: "max-width: 300px; max-height: 200px; border-radius: 8px; margin-top: 10px;"
          end
        end
      end
    end
    f.actions
  end
end
