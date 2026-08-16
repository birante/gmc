ActiveAdmin.register HomePageSection do
  menu parent: "Page d'accueil", label: "Sections", priority: 1

  config.sort_order = "position_asc"

  permit_params :section_type, :title, :description, :is_active, :position, :marquee_image, :marquee_image_mobile

  actions :all, except: []

  filter :section_type, as: :select, collection: -> { HomePageSection.distinct.pluck(:section_type).compact }
  filter :title
  filter :is_active
  filter :position
  filter :created_at

  scope :all, default: true
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  controller do
    def scoped_collection
      super.order(:position)
    end
  end

  member_action :purge_marquee_image, method: :delete do
    resource.marquee_image.purge
    redirect_to admin_home_page_section_path(resource), notice: "Image marquee supprimée."
  end

  member_action :purge_marquee_image_mobile, method: :delete do
    resource.marquee_image_mobile.purge
    redirect_to admin_home_page_section_path(resource), notice: "Image marquee mobile supprimée."
  end

  action_item :create_promo_carousel, only: :index, if: proc { HomePageSection.where(section_type: "promo_carousel").blank? } do
    link_to "Créer Promo Carousel", new_admin_home_page_section_path(
      home_page_section: {
        section_type: "promo_carousel",
        title: "Promo Carousel",
        description: "Bannière promo avec carousel produits",
        is_active: true,
        position: 7
      }
    )
  end

  index do
    selectable_column
    id_column
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
      row :id
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

    if resource.section_type == "marquee"
      panel "Image Marquee" do
        if resource.marquee_image.attached?
          div do
            image_tag resource.marquee_image, style: "max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px;"
          end
          div style: "margin-top: 8px;" do
            link_to "Supprimer l'image", purge_marquee_image_admin_home_page_section_path(resource), method: :delete, data: { confirm: "Supprimer cette image ?" }, class: "button"
          end
        else
          div { "Aucune image uploadée pour le marquee." }
        end

        if resource.marquee_image_mobile.attached?
          hr
          h4 "Image mobile"
          div do
            image_tag resource.marquee_image_mobile, style: "max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px;"
          end
          div style: "margin-top: 8px;" do
            link_to "Supprimer l'image mobile", purge_marquee_image_mobile_admin_home_page_section_path(resource), method: :delete, data: { confirm: "Supprimer cette image mobile ?" }, class: "button"
          end
        else
          div style: "margin-top: 12px;" do
            em "Aucune image mobile uploadée. Le desktop sera utilisé en fallback."
          end
        end
      end
    end

    panel "Slides Hero" do
      div do
        link_to "Nouveau slide", new_admin_hero_slider_slide_path(hero_slider_slide: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.hero_slider_slides.order(:position) do
        column :id
        column :title
        column :badge_text
        column :position
        column :created_at
        column "Actions" do |slide|
          link_to "Voir", admin_hero_slider_slide_path(slide), class: "member_link view_link"
        end
      end
    end

    panel "Bannières Promo" do
      div do
        link_to "Nouvelle bannière", new_admin_promo_banner_path(promo_banner: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.promo_banners.order(:position) do
        column :id
        column :title
        column :cta_text
        column :position
        column :created_at
        column "Actions" do |banner|
          link_to "Voir", admin_promo_banner_path(banner), class: "member_link view_link"
        end
      end
    end

    panel "Bannières Marques Officielles" do
      div do
        link_to "Nouvelle bannière", new_admin_official_brand_banner_path(official_brand_banner: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.official_brand_banners.order(:position) do
        column :id
        column :name
        column :link
        column :position
        column :created_at
        column "Actions" do |banner|
          link_to "Voir", admin_official_brand_banner_path(banner), class: "member_link view_link"
        end
      end
    end

    panel "Bannières Boutiques Locales" do
      div do
        link_to "Nouvelle bannière", new_admin_local_shop_banner_path(local_shop_banner: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.local_shop_banners.order(:position) do
        column :id
        column :name
        column :slug
        column :position
        column :created_at
        column "Actions" do |banner|
          link_to "Voir", admin_local_shop_banner_path(banner), class: "member_link view_link"
        end
      end
    end

    panel "Bannières Secondaires" do
      div do
        link_to "Nouvelle bannière", new_admin_secondary_banner_path(secondary_banner: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.secondary_banners.order(:position_order) do
        column :id
        column :title
        column :link
        column :position_type
        column :position_order
        column :created_at
        column "Actions" do |banner|
          link_to "Voir", admin_secondary_banner_path(banner), class: "member_link view_link"
        end
      end
    end

    panel "Tendances du moment" do
      div do
        link_to "Nouveau groupe", new_admin_home_page_section_group_path(home_page_section_group: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.home_page_section_groups.order(:position) do
        column :id
        column :title
        column :position
        column :created_at
        column "Actions" do |group|
          link_to "Voir", admin_home_page_section_group_path(group), class: "member_link view_link"
        end
      end
    end

    panel "Catégories (items)" do
      div do
        link_to "Nouvel item", new_admin_home_page_section_item_path(home_page_section_item: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.home_page_section_items.order(:position) do
        column :id
        column :title
        column :link
        column :position
        column :created_at
        column "Actions" do |item|
          link_to "Voir", admin_home_page_section_item_path(item), class: "member_link view_link"
        end
      end
    end

    panel "Paramètres" do
      div do
        link_to "Nouveau paramètre", new_admin_home_page_section_setting_path(home_page_section_setting: { home_page_section_id: resource.id }), class: "button"
      end
      table_for resource.home_page_section_settings do
        column :key
        column :value do |setting|
          truncate(setting.value, length: 50)
        end
        column :created_at
        column "Actions" do |setting|
          link_to "Voir", admin_home_page_section_setting_path(setting), class: "member_link view_link"
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de la section" do
      f.input :section_type, as: :select, collection: [
        [ "Marquee", "marquee" ],
        [ "Hero Slider", "hero_slider" ],
        [ "Promo Banners", "promo_banners" ],
        [ "Categories", "categories" ],
        [ "Secondary Banners", "secondary_banners" ],
        [ "Trending Categories", "trending_categories" ],
        [ "Promo Carousel", "promo_carousel" ],
        [ "Local Shops", "local_shops" ],
        [ "Official Brands", "official_brands" ],
        [ "Recommendations", "recommendations" ],
        [ "Newsletter", "newsletter" ]
      ]
      f.input :title
      f.input :description, as: :text
      f.input :is_active
      f.input :position
    end

    if f.object.section_type == "marquee"
      f.inputs "Image Marquee" do
        if f.object.marquee_image.attached?
          f.template.concat(
            f.template.content_tag(:li) do
              f.template.content_tag(:label, "Image actuelle") +
              f.template.content_tag(:div) do
                f.template.image_tag(f.object.marquee_image, style: "max-width: 400px; height: auto; margin-bottom: 8px; display: block;")
              end
            end
          )
        end
        f.input :marquee_image, as: :file, label: "Uploader une image (remplace l'existante)",
          hint: "Desktop recommandé : 1440×60 px (minimum 1200×51 px). Format JPG, PNG ou WebP."

        if f.object.marquee_image_mobile.attached?
          f.template.concat(
            f.template.content_tag(:li) do
              f.template.content_tag(:label, "Image mobile actuelle") +
              f.template.content_tag(:div) do
                f.template.image_tag(f.object.marquee_image_mobile, style: "max-width: 320px; height: auto; margin-bottom: 8px; display: block;")
              end
            end
          )
        end

        f.input :marquee_image_mobile, as: :file, label: "Uploader une image mobile (optionnel)",
          hint: "Mobile recommandé : 1080×120 px (minimum 860×88 px). Si non fournie, l'image desktop est utilisée en fallback."
      end
    end

    f.actions
  end
end
