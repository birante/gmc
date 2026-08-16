ActiveAdmin.register Item do
  menu parent: "Catalogue", priority: 1, label: "Produits"

  # Specify parameters which should be permitted for assignment
  permit_params :shop_id, :product_sub_category_id, :currency_id, :name, :validation_status, :position, :description,
                :delivery_category_id, :keywords, :cash_on_delivery_disabled,
                :default_price, :default_stock_quantity,
                item_attributes_attributes: [ :id, :name, :position, :_destroy, attribute_values_attributes: [ :id, :value, :position, :_destroy ] ],
                variants_attributes: [ :id, :size, :color, :sku, :price, :stock_quantity, :is_default, :_destroy ]

  # or consider:
  #
  # permit_params do
  #   permitted = [:shop_id, :product_sub_category_id, :currency_id, :name, :price, :stock_quantity, :validation_status, :position, :slug, :description]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Configure ActiveAdmin to use FriendlyId for finding resources
  controller do
    def scoped_collection
      # item_attributes: :attribute_values évite le N+1 dans le form d'édition
      # (f.has_many :item_attributes ... f.inputs for: :attribute_values)
      super.includes(:shop, :product_sub_category, :currency, :delivery_category, :variants,
                     item_attributes: :attribute_values)
    end

    def find_resource
      scoped_collection.friendly.find(params[:id])
    end

    # Avant la mise à jour, s'assurer que delivery_category est présent si on approuve
    def update
      if params[:item] && params[:item][:validation_status] == "approved"
        unless params[:item][:delivery_category_id].present?
          resource.errors.add(:delivery_category, "doit être sélectionnée pour approuver le produit")
          render :edit, status: :unprocessable_entity
          return
        end
      end
      super
    end

    # Avant la création, s'assurer que delivery_category est présent si on approuve
    def create
      if params[:item] && params[:item][:validation_status] == "approved"
        unless params[:item][:delivery_category_id].present?
          build_resource.errors.add(:delivery_category, "doit être sélectionnée pour approuver le produit")
          render :new, status: :unprocessable_entity
          return
        end
      end
      super
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :shop
  filter :product_sub_category
  filter :currency
  filter :delivery_category
  filter :name
  filter :validation_status
  filter :position
  filter :description
  filter :created_at
  filter :updated_at
  filter :cash_on_delivery_disabled

  # Add or remove columns to toggle their visibility in the index action
  # tbody_html / row_html : classes pour cibler le design (docs Active Admin)
  index tbody_html: { class: "aa-index-tbody" }, row_html: ->(item) { { class: "aa-index-row" } } do
    selectable_column
    id_column
    column :shop
    column :product_sub_category
    column :currency
    column "Catégorie livraison" do |item|
      if item.delivery_category
        status_tag item.delivery_category.name, class: "ok"
      else
        status_tag "⚠️ Non définie", class: "error"
      end
    end
    column :name
    column I18n.t("active_admin.columns.variants_count") do |item|
      item.variants.size
    end
    column I18n.t("active_admin.columns.views_count"), :views_count
    column I18n.t("active_admin.columns.validation_status", default: "Statut de validation") do |item|
      status_tag(
        I18n.t("active_admin.statuses.#{item.validation_status}", default: item.validation_status.to_s.humanize),
        class: item.validation_status
      )
    end
    column :position
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :shop
      row :product_sub_category
      row :currency
      row :delivery_category
      row :name
      row :validation_status
      row :position
      row "URL Slug (read-only)" do
        resource.slug
      end
      row :description
      row :keywords do |item|
        item.keywords.presence || "—"
      end
      row :cash_on_delivery_disabled do |item|
        status_tag(item.cash_on_delivery_disabled? ? "Oui (cash désactivé)" : "Non", class: item.cash_on_delivery_disabled? ? "warning" : "ok")
      end
      row :created_at
      row :updated_at
    end

    panel "Étape 2️⃣ : Matrice de Variantes" do
      if resource.item_attributes.any?
        div class: "variant-info", style: "margin-bottom: 15px;" do
          p "Nombre de combinaisons possibles: <strong>#{resource.variant_combinations_count}</strong>".html_safe
          p "Variantes créées: <strong>#{resource.variants.where(is_default: false).count}</strong>".html_safe
        end
      end

      table_for resource.variants, html: { style: "width: 100%; font-size: 12px;" } do
        column :id
        column :sku
        if resource.item_attributes.empty?
          column :size
          column :color
        else
          # Afficher dynamiquement les colonnes pour chaque attribut
          resource.item_attributes.ordered.each do |attr|
            column(attr.name) do |variant|
              variant.attribute_values.joins(:item_attribute)
                .where(item_attributes: { id: attr.id })
                .first&.value || "—"
            end
          end
        end
        column :price, sortable: :price
        column :stock_quantity, sortable: :stock_quantity
        column "Actif" do |variant|
          status_tag(variant.is_default ? "Défaut" : "Actif", class: "ok")
        end
        column "Actions" do |v|
          link_to "Modifier le produit", edit_admin_item_path(resource), class: "button", title: "Les variantes sont modifiables dans le formulaire du produit"
        end
      end
    end

    panel "🔗 Lien Public du Produit" do
      div data: { controller: "copy-link" } do
        div style: "display: flex; gap: 10px; margin-bottom: 15px;" do
          input type: "text",
                style: "flex: 1; padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px; background: #f9f9f9; font-size: 13px;",
                value: resource.public_url,
                readonly: true,
                data: { "copy-link-target": "input" }

          button type: "button",
                  style: "padding: 8px 16px; background: #2563eb; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500;",
                  data: { "copy-link-target": "button", action: "copy-link#copy" } do
            "Copier"
          end

          a href: resource.public_url,
            target: "_blank",
            rel: "noopener noreferrer",
            style: "padding: 8px 16px; background: #e5e7eb; color: #374151; text-decoration: none; border-radius: 4px; font-size: 13px; font-weight: 500; display: inline-block;",
            title: "Ouvrir dans un nouvel onglet" do
            "Ouvrir ↗"
          end
        end
      end
    end
    # Section Analytics
    panel "📊 Analytics du Produit" do
      # Récupérer les paramètres de date ou utiliser les 30 derniers jours par défaut
      start_date = params[:analytics_start_date].present? ? Date.parse(params[:analytics_start_date]) : 30.days.ago.to_date
      end_date = params[:analytics_end_date].present? ? Date.parse(params[:analytics_end_date]) : Date.today

      # Filtre de dates
      div class: "analytics-filter", style: "margin-bottom: 20px;" do
        render partial: "admin/items/analytics_filter", locals: { item: resource, start_date: start_date, end_date: end_date }
      end

      # Statistiques de la période
      stats = resource.analytics_summary(period: (end_date - start_date).to_i.days)

      div class: "stats-grid", style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin-bottom: 20px;" do
        div class: "stat-card", style: "background: #f5f5f5; padding: 15px; border-radius: 5px;" do
          h4 "Vues Totales", style: "margin: 0 0 5px 0; font-size: 14px; color: #666;"
          strong resource.views_count, style: "font-size: 24px; color: #333;"
        end

        div class: "stat-card", style: "background: #f5f5f5; padding: 15px; border-radius: 5px;" do
          h4 "Vues (période)", style: "margin: 0 0 5px 0; font-size: 14px; color: #666;"
          strong stats[:recent_views], style: "font-size: 24px; color: #1976d2;"
        end

        div class: "stat-card", style: "background: #f5f5f5; padding: 15px; border-radius: 5px;" do
          h4 "Visiteurs Uniques", style: "margin: 0 0 5px 0; font-size: 14px; color: #666;"
          strong stats[:unique_visitors], style: "font-size: 24px; color: #388e3c;"
        end

        div class: "stat-card", style: "background: #f5f5f5; padding: 15px; border-radius: 5px;" do
          h4 "Ajouts au Panier", style: "margin: 0 0 5px 0; font-size: 14px; color: #666;"
          strong stats[:total_added_to_cart], style: "font-size: 24px; color: #7b1fa2;"
        end

        div class: "stat-card", style: "background: #f5f5f5; padding: 15px; border-radius: 5px;" do
          h4 "Taux d'Ajout Panier", style: "margin: 0 0 5px 0; font-size: 14px; color: #666;"
          strong "#{stats[:add_to_cart_rate]}%", style: "font-size: 24px; color: #f57c00;"
        end
      end

      # Graphique des vues par jour
      h3 "Évolution des vues"
      daily_views_data = resource.daily_views(start_date: start_date, end_date: end_date)
      line_chart daily_views_data, thousands: ","
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations du produit" do
      f.input :shop
      f.input :product_sub_category
      f.input :currency
      f.input :name
      f.input :delivery_category,
              as: :select,
              collection: DeliveryCategory.all.order(:name),
              prompt: "Sélectionner une catégorie de livraison",
              hint: "⚠️ REQUIS pour approuver le produit. Options disponibles: Léger (articles légers), Moyen (taille moyenne), Grand (volumineux).",
              input_html: {
                required: f.object.validation_status == "approved" || params[:item]&.dig(:validation_status) == "approved",
                class: "delivery-category-select"
              }
      f.input :validation_status,
              as: :select,
              collection: Item::VALIDATION_STATUSES.map { |status| [ I18n.t("active_admin.statuses.#{status}", default: status.humanize), status ] },
              hint: "⚠️ Pour approuver un produit, la catégorie de livraison DOIT être sélectionnée.",
              input_html: {
                class: "validation-status-select",
                data: {
                  requires_delivery_category: true
                }
              }
            f.input :cash_on_delivery_disabled, as: :boolean,
              label: "⚠️ Désactiver le paiement cash à la livraison pour ce produit",
              hint: "Par défaut, le cash à la livraison est désactivé pour les nouveaux produits."
      f.input :keywords, as: :text, label: "Mots-clés (SEO / IA)",
              hint: "Liste libre (virgules ou retours ligne). Sert aussi de référence pour l’enrichissement IA."
      f.input :position
      f.input :description
    end

    # Si c'est un nouvel item sans variantes, afficher les champs de la variante par défaut
    if f.object.new_record? && f.object.variants.empty?
      f.inputs "Variante par défaut (obligatoire)" do
        f.input :default_price, label: "Prix", as: :number, step: 0.01,
                hint: "Prix de la variante par défaut"
        f.input :default_stock_quantity, label: "Stock", as: :number,
                hint: "Quantité en stock de la variante par défaut"
      end
    end

    # Section Attributs (Étape 1 du processus de variantes)
    unless f.object.new_record?
      f.inputs "Étape 1️⃣ : Attributs et Valeurs" do
        f.has_many :item_attributes, allow_destroy: true, new_record: true do |attr|
          attr.input :name, label: "Nom de l'attribut (ex: Couleur, Taille, Processeur)"
          attr.input :position, label: "Position", as: :number
          attr.inputs "Valeurs", for: :attribute_values do |av|
            av.input :value, label: "Valeur"
            av.input :position, label: "Position", as: :number
          end
        end
      end
    end

    f.inputs "Variantes" do
      unless f.object.new_record?
        f.has_many :variants, allow_destroy: true, new_record: true do |v|
          v.input :is_default, label: "Variante par défaut", as: :boolean,
                  hint: "Cocher si c'est la variante par défaut"
          v.input :sku, label: "SKU", hint: "Généré automatiquement si vide"
          v.input :size, label: "Taille (déprécié)"
          v.input :color, label: "Couleur (déprécié)"
          v.input :price, label: "Prix", hint: "Si vide, hérite du prix de la variante par défaut"
          v.input :stock_quantity, label: "Stock", hint: "Si vide, hérite du stock de la variante par défaut"
        end
      end
    end

    f.actions
  end

  # Custom action pour générer les variantes depuis les attributs
  action_item :generate_variants, only: :show do
    if resource.item_attributes.any?
      link_to "🎯 Générer les variantes", generate_variants_admin_item_path(resource), method: :post, class: "button", data: { confirm: "Cela va créer toutes les combinaisons possibles. Continuer ?" }
    end
  end

  action_item :regenerate_variants, only: :show do
    if resource.item_attributes.any? && resource.variants.where(is_default: false).any?
      link_to "🔄 Régénérer les variantes", regenerate_variants_admin_item_path(resource), method: :post, class: "button", data: { confirm: "Cela va supprimer et recréer toutes les variantes. Continuer ?" }
    end
  end

  member_action :generate_variants, method: :post do
    resource.generate_variants!
    redirect_to admin_item_path(resource), notice: "Variantes générées avec succès!"
  end

  member_action :regenerate_variants, method: :post do
    resource.regenerate_variants!
    redirect_to admin_item_path(resource), notice: "Variantes régénérées avec succès!"
  end
end
