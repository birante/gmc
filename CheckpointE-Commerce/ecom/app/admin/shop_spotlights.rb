ActiveAdmin.register ShopSpotlight do
  menu parent: "Page d'accueil", label: "Boutiques mises en avant (Sharp)", priority: 9

  permit_params :home_page_section_id, :shop_id, :slogan, :position, :promo_title, :promo_subtitle, :item_ids, :promo_image

  filter :shop
  filter :home_page_section
  filter :position
  filter :created_at

  index do
    selectable_column
    id_column
    column "Boutique" do |spotlight|
      if spotlight.shop
        link_to spotlight.shop.name, admin_shop_path(spotlight.shop)
      else
        status_tag("Aucune boutique", class: "error")
      end
    end
    column "Image promo" do |spotlight|
      if spotlight.promo_image.attached?
        image_tag url_for(spotlight.promo_image.variant(resize_to_limit: [ 80, 80 ])), class: "admin-thumbnail"
      else
        status_tag("Aucune image", class: "warning")
      end
    end
    column :slogan do |spotlight|
      truncate(spotlight.slogan, length: 50)
    end
    column "Produits" do |spotlight|
      ids = spotlight.item_ids_array
      if ids.any?
        "#{ids.count} produit(s)"
      else
        status_tag("Aucun", class: "warning")
      end
    end
    column :position
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :home_page_section do |spotlight|
        link_to spotlight.home_page_section.title, admin_home_page_section_path(spotlight.home_page_section) if spotlight.home_page_section
      end
      row :shop do |spotlight|
        if spotlight.shop
          link_to spotlight.shop.name, admin_shop_path(spotlight.shop)
        end
      end
      row "Logo de la boutique" do |spotlight|
        if spotlight.shop&.logo&.attached?
          image_tag url_for(spotlight.shop.logo.variant(resize_to_limit: [ 200, 200 ]))
        else
          status_tag("Aucun logo", class: "warning")
        end
      end
      row :slogan
      row :promo_title
      row :promo_subtitle
      row "Image promotionnelle" do |spotlight|
        if spotlight.promo_image.attached?
          div do
            image_tag url_for(spotlight.promo_image.variant(resize_to_limit: [ 600, 400 ]))
          end
        else
          status_tag("Aucune image", class: "warning")
        end
      end
      row :item_ids do |spotlight|
        spotlight.item_ids
      end
      row "Produits sélectionnés" do |spotlight|
        items = spotlight.items
        if items.any?
          table_for items do
            column "Image" do |item|
              if item.main_image.attached?
                image_tag url_for(item.main_image.variant(resize_to_limit: [ 60, 60 ]))
              end
            end
            column "Nom" do |item|
              link_to item.name, admin_item_path(item)
            end
            column "Prix" do |item|
              number_to_currency(item.variants.first&.price, unit: item.currency.symbol)
            end
          end
        else
          status_tag("Aucun produit", class: "warning")
        end
      end
      row :position
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Section" do
      if f.object.new_record?
        f.input :home_page_section,
                as: :select,
                collection: HomePageSection.where(section_type: "shop_spotlight").map { |s| [ s.title, s.id ] },
                include_blank: false,
                hint: "Section 'Boutiques mises en avant' automatiquement sélectionnée"
      else
        f.input :home_page_section, input_html: { disabled: true }
        f.hidden_field :home_page_section_id
      end
    end

    f.inputs "Boutique" do
      f.input :shop,
              as: :select,
              collection: Shop.where(shop_type: "official").order(:name).map { |s| [ s.name, s.id ] },
              include_blank: "Sélectionnez une boutique officielle",
              hint: "Seules les boutiques officielles sont disponibles"

      if f.object.shop
        para do
          strong "Logo de la boutique:"
          br
          if f.object.shop.logo.attached?
            image_tag url_for(f.object.shop.logo.variant(resize_to_limit: [ 150, 150 ]))
          else
            status_tag("Aucun logo pour cette boutique", class: "warning")
          end
        end
      end
    end

    f.inputs "Contenu" do
      f.input :slogan,
              as: :text,
              input_html: { rows: 2, placeholder: "Ex: La qualité japonaise depuis 100 Ans" },
              hint: "Slogan ou phrase d'accroche de la boutique (max 500 caractères)"

      f.input :promo_title,
              as: :string,
              input_html: { placeholder: "Ex: NEW YEAR" },
              hint: "Titre de la promotion (optionnel)"

      f.input :promo_subtitle,
              as: :string,
              input_html: { placeholder: "Ex: Offres exceptionnelles" },
              hint: "Sous-titre de la promotion (optionnel)"
    end

    f.inputs "Image promotionnelle" do
      if f.object.promo_image.attached?
        para do
          strong "Image actuelle:"
          br
          image_tag url_for(f.object.promo_image.variant(resize_to_limit: [ 400, 300 ]))
        end
      end

      f.input :promo_image,
              as: :file,
              hint: "Image promotionnelle affichée sur le côté gauche (format recommandé: 400x500px, JPG/PNG)"
    end

    f.inputs "Produits" do
      f.input :item_ids,
              as: :text,
              input_html: { rows: 3, placeholder: "123, 456, 789, 101" },
              hint: "IDs des produits à afficher dans le carousel, séparés par des virgules. Sélectionnez 4-8 produits de la boutique choisie ci-dessus."

      if f.object.shop_id.present?
        para do
          strong "Pour trouver les IDs des produits:"
          br
          link_to "Voir tous les produits de #{f.object.shop.name}", admin_items_path(q: { shop_id_eq: f.object.shop_id }), target: "_blank", class: "button"
        end
      end
    end

    f.inputs "Position" do
      f.input :position,
              as: :number,
              input_html: { min: 1, value: f.object.position || 1 },
              hint: "Ordre d'affichage (1 = premier)"
    end

    f.actions
  end
end
