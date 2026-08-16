# frozen_string_literal: true

ActiveAdmin.register Shop do
  menu parent: "Boutiques & Vendeurs", priority: 1, label: "Boutiques"

  # Specify parameters which should be permitted for assignment
  permit_params :vendor_id, :name, :address, :description, :primary_color, :secondary_color, :status, :code, :shop_type, :commission_rate, :logo, :banner_image,
                shop_banners_attributes: [ :id, :position, :title, :cta_text, :cta_link, :image, :_destroy ]

  # or consider:
  #
  # permit_params do
  #   permitted = [:vendor_id, :slug, :name, :address, :description, :primary_color, :secondary_color, :status, :code]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Configure ActiveAdmin to use FriendlyId for finding resources
  controller do
    # Préloads pour éviter les N+1 sur l'index (column :vendor) et le show/edit
    def scoped_collection
      super.includes(:vendor)
    end

    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  # Action membre pour créer un payout mensuel
  member_action :create_monthly_payout, method: :post do
    shop = Shop.friendly.find(params[:id])
    begin
      FinanceManager.process_monthly_payout(shop)
      redirect_to admin_shop_path(shop), notice: "Payout mensuel créé avec succès"
    rescue => e
      redirect_to admin_shop_path(shop), alert: "Erreur lors de la création du payout: #{e.message}"
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :vendor
  filter :name
  filter :address
  filter :description
  filter :primary_color
  filter :secondary_color
  filter :status
  filter :shop_type, as: :select, collection: -> { Shop.shop_types.map { |k, v| [ k.humanize, k ] } }
  filter :code
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :vendor
    column :name
    column :address
    column :description
    column :primary_color
    column :secondary_color
    column :status
    column :shop_type do |shop|
      status_tag shop.shop_type, class: shop.shop_type
    end
    column :code
    column I18n.t("active_admin.columns.total_views"), :views_count
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :vendor
      row :name
      row :address
      row :description
      row :primary_color
      row :secondary_color
      row :status
      row :shop_type do |shop|
        status_tag shop.shop_type, class: shop.shop_type
      end
      row :commission_rate do |shop|
        number_to_percentage(shop.commission_rate.to_f * 100, precision: 2)
      end
      row :code
      row "Logo" do |shop|
        if shop.logo.attached?
          image_tag url_for(shop.logo), style: "max-width: 100px; max-height: 100px; border-radius: 4px;", alt: shop.name
        else
          "—"
        end
      end
      row "Bannière (ancienne)" do |shop|
        if shop.banner_image.attached?
          image_tag url_for(shop.banner_image), style: "max-width: 300px; max-height: 150px; border-radius: 4px;", alt: shop.name
        else
          "—"
        end
      end
      row :created_at
      row :updated_at
    end

    # Section Bannières
    panel "🎨 Bannières de la Boutique" do
      div style: "margin-bottom: 15px;" do
        link_to "Ajouter une bannière", new_admin_shop_banner_path(shop_banner: { shop_id: resource.id }), class: "button"
      end

      if resource.shop_banners.any?
        table_for resource.shop_banners.order(:position) do
          column "Position", :position
          column "Titre", :title
          column "Image" do |banner|
            if banner.image.attached?
              image_tag url_for(banner.image), style: "max-width: 150px; max-height: 80px; border-radius: 4px;", alt: banner.title
            else
              "—"
            end
          end
          column "CTA", :cta_text
          column "Lien", :cta_link
          column "Actions" do |banner|
            link_to "Modifier", edit_admin_shop_banner_path(banner), class: "button"
          end
        end
      else
        para style: "color: #666; font-style: italic;" do
          "Aucune bannière configurée. Utilisez le lien ci-dessus pour en ajouter."
        end
      end
    end

    # Section Analytics
    panel "📊 Analytics de la Boutique" do
      # Récupérer les paramètres de date ou utiliser les 30 derniers jours par défaut
      start_date = params[:analytics_start_date].present? ? Date.parse(params[:analytics_start_date]) : 30.days.ago.to_date
      end_date = params[:analytics_end_date].present? ? Date.parse(params[:analytics_end_date]) : Date.today

      # Filtre de dates
      div class: "analytics-filter", style: "margin-bottom: 20px;" do
        render partial: "admin/shops/analytics_filter", locals: { shop: resource, start_date: start_date, end_date: end_date }
      end

      # Statistiques de la période
      stats = resource.analytics_summary(period: (end_date - start_date).to_i.days)

      div class: "stats-grid", style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;" do
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
          h4 "Taux de Conversion", style: "margin: 0 0 5px 0; font-size: 14px; color: #666;"
          strong "#{stats[:conversion_rate]}%", style: "font-size: 24px; color: #f57c00;"
        end
      end

      # Graphique des vues par jour
      h3 "Évolution des vues"
      daily_views_data = resource.daily_views(start_date: start_date, end_date: end_date)
      line_chart daily_views_data, thousands: ","

      # Top produits de la boutique
      h3 "Top 10 Produits les Plus Vus", style: "margin-top: 30px;"
      table_for stats[:top_items] do
        column "Produit" do |item|
          link_to item.name, admin_item_path(item)
        end
        column "Vues Totales", :views_count
        column "Catégorie" do |item|
          item.product_sub_category&.name
        end
        column "Statut", :validation_status
      end
    end

    # Section Finances
    panel "💰 Finances" do
      div style: "margin-bottom: 15px;" do
        strong "Solde disponible: "
        span style: "font-size: 20px; color: #388e3c;" do
          number_to_currency(resource.balance || 0, unit: resource.currency&.symbol || "FCFA")
        end
      end

      div style: "margin-bottom: 15px;" do
        strong "Montant en attente de reversement: "
        span style: "font-size: 18px; color: #f57c00;" do
          number_to_currency(resource.pending_payout_amount || 0, unit: resource.currency&.symbol || "FCFA")
        end
      end

      if resource.pending_payout_amount.to_f > 0
        div style: "margin-top: 15px;" do
          form_tag create_monthly_payout_admin_shop_path(resource), method: :post, style: "display: inline-block;" do
            submit_tag "Créer un reversement mensuel",
              class: "button",
              data: { confirm: "Êtes-vous sûr de vouloir créer un reversement pour #{number_to_currency(resource.pending_payout_amount, unit: resource.currency&.symbol || 'FCFA')} ?" }
          end
        end
      else
        para style: "color: #666; font-style: italic;" do
          "Aucun montant en attente de reversement"
        end
      end

      h3 style: "margin-top: 20px;" do "Reversements récents" end
      table_for resource.payouts.order(created_at: :desc).limit(5) do
        column :id do |payout|
          link_to payout.id, admin_payout_path(payout)
        end
        column :amount do |payout|
          number_to_currency(payout.amount, unit: payout.currency&.symbol || "FCFA")
        end
        column :status do |payout|
          status_tag payout.status,
            class: case payout.status
                   when "paid" then "ok"
                   when "pending" then "warning"
                   when "processing" then "yes"
                   when "failed" then "error"
                   else "no"
                   end
        end
        column "Période" do |payout|
          "#{payout.payout_month}/#{payout.payout_year}"
        end
        column :created_at
      end

      div style: "margin-top: 10px;" do
        link_to "Voir tous les reversements", admin_payouts_path(q: { shop_id_eq: resource.id }), class: "button"
      end

      h3 style: "margin-top: 20px;" do "Transactions récentes" end
      table_for resource.shop_transactions.order(created_at: :desc).limit(10) do
        column :id do |transaction|
          link_to transaction.id, admin_shop_transaction_path(transaction)
        end
        column :transaction_type do |transaction|
          status_tag transaction.transaction_type,
            class: transaction.transaction_type == "credit" ? "ok" : "error"
        end
        column :amount do |transaction|
          number_to_currency(transaction.amount, unit: transaction.currency&.symbol || "FCFA")
        end
        column :description
        column :order do |transaction|
          if transaction.order
            link_to "##{transaction.order.id}", admin_order_path(transaction.order)
          else
            "-"
          end
        end
        column :payout do |transaction|
          if transaction.payout
            link_to "##{transaction.payout.id}", admin_payout_path(transaction.payout)
          else
            "-"
          end
        end
        column :created_at
      end

      div style: "margin-top: 10px;" do
        link_to "Voir toutes les transactions", admin_shop_transactions_path(q: { shop_id_eq: resource.id }), class: "button"
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :vendor
      f.input :name
      f.input :address
      f.input :description
      f.input :primary_color, hint: "Couleur principale (format hex: #551694)"
      f.input :secondary_color, hint: "Couleur secondaire (format hex: #8B5CF6)"
      f.input :status,
              as: :select,
              collection: Shop.statuses.keys.map { |status| [ status.humanize, status ] },
              selected: (f.object.status.presence || "pending")
      f.input :shop_type, as: :select, collection: Shop.shop_types.map { |k, v| [ k.humanize, k ] }
      f.input :commission_rate, hint: "Part plateforme sur chaque vente livrée (ex. 0,10 = 10 %). Entre 0 et 1."
      f.input :code
      f.input :logo, as: :file, hint: "Logo de la boutique. Taille recommandée : 400×400px (carré). Format : SVG ou PNG transparent de préférence. Affiché de 48px à 112px selon les pages."
      f.input :banner_image, as: :file, hint: "Bannière principale (méthode ancienne — préférer les bannières multiples ci-dessous). Taille recommandée : 1280×400px. Format : JPG, PNG."

      if f.object.logo.attached?
        f.inputs "Logo actuel" do
          div do
            image_tag url_for(f.object.logo), style: "max-width: 150px; max-height: 150px; border-radius: 8px; margin-top: 10px;"
          end
        end
      end

      if f.object.banner_image.attached?
        f.inputs "Bannière actuelle" do
          div do
            image_tag url_for(f.object.banner_image), style: "max-width: 400px; max-height: 200px; border-radius: 8px; margin-top: 10px;"
          end
        end
      end
    end

    f.inputs "Bannières multiples" do
      f.has_many :shop_banners, heading: "Bannières", allow_destroy: true, new_record: "Ajouter une bannière" do |banner_form|
        banner_form.input :position
        banner_form.input :title
        banner_form.input :cta_text
        banner_form.input :cta_link
        banner_form.input :image, as: :file, hint: "Taille recommandée : 1200×400px (pleine largeur). Format : JPG, PNG."

        if banner_form.object.image.attached?
          banner_form.inputs "Image actuelle" do
            div do
              image_tag url_for(banner_form.object.image), style: "max-width: 200px; max-height: 100px; border-radius: 4px; margin-top: 5px;"
            end
          end
        end
      end
    end

    f.actions
  end
end
