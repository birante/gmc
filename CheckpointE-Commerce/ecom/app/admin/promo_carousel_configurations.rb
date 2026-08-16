ActiveAdmin.register_page "Promo Carousel" do
  menu parent: "Page d'accueil", label: "Promo Carousel (Sharp)", priority: 7

  content title: "Configuration Promo Carousel" do
    promo_section = HomePageSection.find_by(section_type: "promo_carousel")

    if promo_section.nil?
      div class: "blank_slate_container" do
        span class: "blank_slate" do
          span "La section Promo Carousel n'existe pas. Exécutez les seeds."
        end
      end
    else
      # Charger les settings actuels
      settings = promo_section.home_page_section_settings.index_by { |s| s.key }
      current_shop_id = settings["shop_id"]&.value.to_i
      current_item_ids = (settings["item_ids"]&.value || "").to_s.split(",").map { |s| s.strip }.map { |s| s.to_i }.reject { |id| id.zero? }

      # Panel d'état
      panel "État actuel" do
        attributes_table_for promo_section do
          row("Actif") { promo_section.is_active ? status_tag("Oui", class: "ok") : status_tag("Non", class: "error") }
          row("Position") { promo_section.position }
          row("Label catégorie") { settings["category_label"]&.value }
          row("Titre") { settings["title"]&.value }
          row("Sous-titre") { settings["subtitle"]&.value }
          row("Texte réduction") { settings["discount_text"]&.value }
          row("Suffixe réduction") { settings["discount_suffix"]&.value }
          row("Date fin countdown") { settings["countdown_date"]&.value }
          row("Boutique") do
            if current_shop_id > 0
              shop = Shop.find_by(id: current_shop_id)
              shop ? link_to(shop.name, admin_shop_path(shop)) : "Boutique ##{current_shop_id} introuvable"
            else
              status_tag("Non définie", class: "warning")
            end
          end
          row("Produits") do
            if current_item_ids.any?
              items = Item.where(id: current_item_ids)
              div do
                items.each do |item|
                  div do
                    link_to item.name, admin_item_path(item), target: "_blank"
                  end
                end
                para "#{items.count} produit(s) sélectionné(s)", style: "margin-top: 10px; font-weight: bold;"
              end
            else
              status_tag("Aucun produit", class: "warning")
            end
          end
        end
      end

      # Formulaire de configuration
      panel "Configuration" do
        render partial: "admin/promo_carousel_config_form", locals: { promo_section: promo_section, settings: settings, current_shop_id: current_shop_id, current_item_ids: current_item_ids }
      end

      # Aide visuelle
      panel "Aperçu de la section" do
        div style: "padding: 20px; background: #f4f4f4; border-radius: 4px;" do
          para "Cette section affiche une grande bannière violette avec :", style: "margin-bottom: 10px;"
          ul do
            li "À gauche : Informations de la promotion (label, titre, description, badge réduction, countdown)"
            li "À droite : Carousel défilant avec les produits sélectionnés"
          end
          para "Position sur la page d'accueil : Entre 'Tendances du moment' et 'Boutiques locales'",
               style: "margin-top: 15px; font-weight: bold; color: #551694;"
        end
      end
    end
  end

  page_action :create, method: :post do
    promo_section = HomePageSection.find_by(section_type: "promo_carousel")

    unless promo_section
      redirect_to admin_promo_carousel_path, alert: "❌ Section Promo Carousel introuvable. Lancez les seeds ou créez la section depuis Page d'accueil."
      return
    end

    if params[:promo_carousel_config]
      config = params[:promo_carousel_config]

      # Mettre à jour is_active de la section
      if config[:is_active]
        promo_section.update(is_active: config[:is_active] == "1")
      end

      # Mettre à jour les settings
      setting_keys = %w[category_label title subtitle discount_text discount_suffix countdown_date shop_id item_ids]

      setting_keys.each do |key|
        if config[key.to_sym]
          setting = promo_section.home_page_section_settings.find_or_initialize_by(key: key)
          setting.value = config[key.to_sym].to_s
          setting.save!
        end
      end

      # Vider le cache
      Rails.cache.clear

      redirect_to admin_promo_carousel_path, notice: "✅ Configuration Promo Carousel enregistrée avec succès !"
    else
      redirect_to admin_promo_carousel_path, alert: "❌ Erreur : Aucune donnée reçue"
    end
  end
end
