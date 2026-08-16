# frozen_string_literal: true

ActiveAdmin.register ShopPageHeaderSlide do
  menu parent: "Page Boutique", label: "Header (slides)", priority: 1

  permit_params :shop_id, :link, :button_text, :position, :image, :image_tablet, :image_mobile

  config.sort_order = "position_asc"

  member_action :purge_image_tablet, method: :delete do
    resource.image_tablet.purge
    redirect_to admin_shop_page_header_slide_path(resource), notice: "Image tablette supprimée."
  end

  member_action :purge_image_mobile, method: :delete do
    resource.image_mobile.purge
    redirect_to admin_shop_page_header_slide_path(resource), notice: "Image mobile supprimée."
  end

  filter :shop
  filter :button_text
  filter :position
  filter :created_at

  controller do
    def scoped_collection
      super.includes(:shop, image_attachment: :blob, image_tablet_attachment: :blob, image_mobile_attachment: :blob).order(:position)
    end
  end

  index do
    selectable_column
    id_column
    column :shop
    column :position
    column "Image (Desktop)" do |slide|
      if slide.image.attached?
        image_tag slide.image, style: "max-width: 80px; max-height: 50px; border-radius: 4px;", alt: "Slide"
      else
        "—"
      end
    end
    column "Tablette" do |slide|
      if slide.image_tablet.attached?
        image_tag slide.image_tablet, style: "max-width: 80px; max-height: 50px; border-radius: 4px;", alt: "Slide tablette"
      else
        "—"
      end
    end
    column "Mobile" do |slide|
      if slide.image_mobile.attached?
        image_tag slide.image_mobile, style: "max-width: 80px; max-height: 50px; border-radius: 4px;", alt: "Slide mobile"
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
      row :position
      row :link
      row :button_text
      row "Image Desktop" do |slide|
        if slide.image.attached?
          image_tag url_for(slide.image), style: "max-width: 400px; max-height: 200px; border-radius: 8px;", alt: "Slide"
        else
          "Aucune image"
        end
      end
      row "Image Tablette" do |slide|
        if slide.image_tablet.attached?
          image_tag url_for(slide.image_tablet), style: "max-width: 360px; max-height: 200px; border-radius: 8px;", alt: "Slide tablette"
        else
          "Aucune image (utilise Desktop)"
        end
      end
      row "Image Mobile" do |slide|
        if slide.image_mobile.attached?
          image_tag url_for(slide.image_mobile), style: "max-width: 320px; max-height: 200px; border-radius: 8px;", alt: "Slide mobile"
        else
          "Aucune image (utilise Tablette ou Desktop)"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Slide du header (photo + lien + bouton)" do
      f.input :shop
      f.input :position, hint: "Ordre d'affichage (1, 2, 3...). Plusieurs slides = carousel."

      f.input :image,
              as: :file,
              label: "Image Desktop (≥ 1024px)",
              hint: f.object.image.attached? ? image_tag(url_for(f.object.image), style: "max-width: 200px; margin-top: 10px;") : "Desktop recommandé : 1600×420px (minimum 1200×420px). Format : JPG, PNG, WebP."

      if f.object.image_tablet.attached?
        f.template.concat(
          f.template.content_tag(:li) do
            f.template.content_tag(:label, "Image tablette actuelle") +
            f.template.content_tag(:div) do
              f.template.image_tag(url_for(f.object.image_tablet), style: "max-width: 200px; margin-top: 10px; display: block;") +
              f.template.link_to("Supprimer l'image tablette", purge_image_tablet_admin_shop_page_header_slide_path(f.object), method: :delete, data: { confirm: "Supprimer cette image tablette ?" }, class: "button")
            end
          end
        )
      end

      f.input :image_tablet,
              as: :file,
              label: "Image Tablette (768–1023px, optionnelle)",
              hint: "Tablette recommandé : 1024×420px. Si absente, l'image desktop est utilisée en fallback."

      if f.object.image_mobile.attached?
        f.template.concat(
          f.template.content_tag(:li) do
            f.template.content_tag(:label, "Image mobile actuelle") +
            f.template.content_tag(:div) do
              f.template.image_tag(url_for(f.object.image_mobile), style: "max-width: 200px; margin-top: 10px; display: block;") +
              f.template.link_to("Supprimer l'image mobile", purge_image_mobile_admin_shop_page_header_slide_path(f.object), method: :delete, data: { confirm: "Supprimer cette image mobile ?" }, class: "button")
            end
          end
        )
      end

      f.input :image_mobile,
              as: :file,
              label: "Image Mobile (< 768px, optionnelle)",
              hint: "Mobile recommandé : 768×420px. Si absente, l'image tablette ou desktop est utilisée en fallback."

      f.input :link, hint: "URL du lien (ex: /fr/produits, #products-section)"
      f.input :button_text, hint: "Texte du bouton (ex: Découvrir, Voir les offres)"
    end
    f.actions
  end
end
