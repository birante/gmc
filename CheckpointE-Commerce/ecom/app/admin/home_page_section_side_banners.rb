# frozen_string_literal: true

ActiveAdmin.register HomePageSectionSideBanner do
  menu parent: "Page d'accueil", label: "Made in Senegal (Bannière)", priority: 9

  permit_params :home_page_section_id, :title, :subtitle, :description, :cta_text,
                :cta_link, :bg_color, :text_color, :position, :is_active, :image

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
    column :subtitle
    column "Image" do |banner|
      if banner.image.attached?
        image_tag(url_for(banner.image), style: "width: 80px; height: 80px; object-fit: cover; border-radius: 8px;")
      else
        "Pas d'image"
      end
    end
    column :position
    column "Actif" do |banner|
      status_tag(banner.is_active? ? "Oui" : "Non", class: banner.is_active? ? "ok" : "error")
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section
      row :title
      row :subtitle
      row :description
      row :cta_text
      row :cta_link
      row :bg_color do |banner|
        content_tag(:span, banner.bg_color, style: "display: inline-block; padding: 5px 10px; background: #{banner.bg_color}; color: #{banner.text_color}; border-radius: 4px;")
      end
      row :text_color do |banner|
        content_tag(:span, banner.text_color, style: "display: inline-block; padding: 5px 10px; background: #{banner.text_color}; color: #{banner.bg_color}; border-radius: 4px;")
      end
      row("Image") do |banner|
        if banner.image.attached?
          image_tag(url_for(banner.image), style: "max-width: 400px; max-height: 400px; border-radius: 8px;")
        else
          "Pas d'image"
        end
      end
      row :position
      row("Actif") { |banner| banner.is_active? ? "Oui" : "Non" }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Made in Senegal (Bannière)" do
      f.input :home_page_section,
              label: "Section",
              collection: HomePageSection.where(section_type: "local_shops"),
              hint: "Choisir la section 'local_shops' (Boutiques Locales)."
      f.input :title, label: "Titre principal", hint: "Ex: Made in Senegal", input_html: { placeholder: "Made in Senegal" }
      f.input :subtitle, label: "Sous-titre", hint: "Ex: Produits du terroir", input_html: { placeholder: "Produits du terroir" }
      f.input :description, label: "Description", hint: "Ex: Explorer tous vos produits locaux", input_html: { placeholder: "Explorer tous vos produits locaux", rows: 3 }
      f.input :cta_text, label: "Texte du bouton", hint: "Ex: Voir plus", input_html: { placeholder: "Voir plus" }
      f.input :cta_link, label: "Lien du bouton", hint: "Ex: /fr/boutiques/locales", input_html: { placeholder: "/fr/boutiques/locales" }
      f.input :image,
              as: :file,
              label: "Image de fond",
              hint: "Taille recommandée : 312x614px. Format : JPG, PNG"
      f.input :bg_color, label: "Couleur de fond", hint: "Code hexadécimal (ex: #f3de6d)", input_html: { type: :color, value: f.object.bg_color || "#f3de6d" }
      f.input :text_color, label: "Couleur du texte", hint: "Code hexadécimal (ex: #ffffff)", input_html: { type: :color, value: f.object.text_color || "#ffffff" }
      f.input :position, label: "Position", hint: "Ordre d'affichage"
      f.input :is_active, label: "Actif"
    end

    f.actions
  end
end
