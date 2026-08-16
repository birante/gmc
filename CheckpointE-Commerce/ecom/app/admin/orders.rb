# frozen_string_literal: true

ActiveAdmin.register Order do
  menu parent: "E-Commerce", priority: 1, label: "Commandes"

  # Specify parameters which should be permitted for assignment
  permit_params :user_id, :delivery_zone_id, :delivery_slot_id, :currency_id,
                :total_amount, :delivery_fee, :final_amount, :status,
                :delivery_address, :notes,
                :departure_date, :estimated_arrival_date,
                order_items_attributes: [ :id, :item_id, :shop_id, :item_variant_id, :quantity, :unit_price, :total_price, :delivery_status, :_destroy ]

  # For security, limit the actions that should be available
  actions :all, except: [ :destroy ]

  # Configure ActiveAdmin to use FriendlyId for finding resources
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end

    def scoped_collection
      super.includes(:user, :currency, order_items: { item: :shop })
    end
  end

  member_action :update_status, method: :patch do
    if resource.update_status!(params[:new_status], changed_by: nil)
      # L'historique et departure_date sont gérés automatiquement par les callbacks AASM
      redirect_to resource_path(resource), notice: "Statut mis à jour avec succès"
    else
      redirect_to resource_path(resource), alert: "Erreur lors de la mise à jour du statut. Transition invalide."
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :user
  filter :delivery_zone
  filter :delivery_slot,
         as: :select,
         collection: -> {
           DeliverySlot.order(:start_time).map do |slot|
             [ slot.time_range, slot.id ]
           end
         }
  filter :currency
  filter :status, as: :select, collection: -> { Order.aasm.states.map { |s| [ s.name.to_s.humanize, s.name.to_s ] } }
  filter :total_amount
  filter :final_amount
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :user do |order|
      link_to order.user.full_name, admin_user_path(order.user) if order.user
    end
    column "Boutiques" do |order|
      order.order_items.includes(item: :shop).map { |oi| oi.item&.shop&.name }.compact.uniq.join(", ")
    end
    column :total_amount do |order|
      number_to_currency(order.total_amount, unit: order.currency&.symbol || "€")
    end
    column :delivery_fee do |order|
      number_to_currency(order.delivery_fee, unit: order.currency&.symbol || "€")
    end
    column :final_amount do |order|
      number_to_currency(order.final_amount, unit: order.currency&.symbol || "€")
    end
    column :status do |order|
      status_tag order.status, class: order.status
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :user do |order|
        link_to order.user.full_name, admin_user_path(order.user) if order.user
      end
      row :delivery_zone
      row :delivery_slot do |order|
        order.delivery_slot&.time_range
      end
      row :currency do |order|
        "#{order.currency&.name} (#{order.currency&.symbol})"
      end
      row :total_amount do |order|
        number_to_currency(order.total_amount, unit: order.currency&.symbol || "€")
      end
      row :delivery_fee do |order|
        number_to_currency(order.delivery_fee, unit: order.currency&.symbol || "€")
      end
      row :final_amount do |order|
        number_to_currency(order.final_amount, unit: order.currency&.symbol || "€")
      end
      row :status do |order|
        div do
          status_tag order.status, class: order.status
        end
        if order.available_next_statuses.any?
          div style: "margin-top: 10px;" do
            form_tag update_status_admin_order_path(order), method: :patch do
              div style: "display: flex; align-items: center; gap: 10px;" do
                options = [ [ order.status.humanize, order.status ] ]
                order.available_next_statuses.each { |s| options << [ s.humanize, s ] }
                select_tag "new_status",
                  options_for_select(options, order.status),
                  { class: "select2-input", style: "min-width: 150px;" }
                submit_tag "Changer le statut", class: "button"
              end
            end
          end
        else
          div style: "margin-top: 10px; color: #666; font-style: italic;" do
            "État final - aucune modification possible"
          end
        end
      end
      row :delivery_address
      row("Notes de livraison") { |o| o.notes }
      row "URL Slug (read-only)" do
        resource.slug
      end
      row :created_at
      row :updated_at
    end

    panel "Articles commandés" do
      table_for order.order_items.includes(:item) do
        column "Article" do |oi|
          link_to oi.item&.name, admin_item_path(oi.item) if oi.item
        end
        column "Boutique" do |oi|
          link_to oi.item&.shop&.name, admin_shop_path(oi.item.shop) if oi.item&.shop
        end
        column :quantity
        column :unit_price do |oi|
          number_to_currency(oi.unit_price, unit: order.currency&.symbol || "€")
        end
        column :total_price do |oi|
          number_to_currency(oi.total_price, unit: order.currency&.symbol || "€")
        end
      end
    end

    panel "Paiements" do
      table_for order.payments.includes(:payment_method) do
        column :id
        column :payment_method do |payment|
          payment.payment_method&.name
        end
        column :amount do |payment|
          number_to_currency(payment.amount, unit: order.currency&.symbol || "€")
        end
        column :transaction_id
        column :status do |payment|
          status_tag payment.status, class: payment.status
        end
        column :created_at
      end
    end

    panel "Historique de suivi" do
      if order.order_status_histories.any?
        table_for order.order_status_histories.ordered do
          column "Date" do |history|
            history.created_at.strftime("%d/%m/%Y %H:%M")
          end
          column "Statut" do |history|
            status_tag history.status, class: history.status
          end
          column "Message" do |history|
            history.note
          end
          column "Modifié par" do |history|
            history.changed_by_name
          end
        end
      else
        para "Aucun historique disponible"
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de la commande" do
      f.input :user
      f.input :currency
      f.input :status, as: :select, collection: Order.aasm.states.map { |s| [ s.name.to_s.humanize, s.name.to_s ] }
      f.input :total_amount, hint: "Montant total des articles"
    end

    f.inputs "Livraison" do
      f.input :delivery_zone
      f.input :delivery_slot, label: "Créneau de livraison"
      f.input :delivery_fee, hint: "Frais de livraison calculés automatiquement"
      f.input :delivery_address, as: :text
      f.input :notes, as: :text, label: "Notes de livraison"
    end

    f.inputs "Total" do
      f.input :final_amount, hint: "Montant total + frais de livraison"
    end

    f.inputs "Articles de la commande", hint: "Modifiez article, quantité ou prix unitaire ; le total ligne est recalculé automatiquement. Les totaux commande sont recalculés après enregistrement." do
      f.has_many :order_items, heading: false, new_record: true, allow_destroy: true do |oi|
        oi.input :item
        oi.input :shop, hint: "Doit correspondre à la boutique du produit"
        oi.input :item_variant,
                 collection: (oi.object.item_id.present? ? ItemVariant.where(item_id: oi.object.item_id).order(:id) : ItemVariant.none),
                 hint: "Optionnel — choisir après l’article"
        oi.input :quantity
        oi.input :unit_price
        oi.input :total_price, hint: "Recalculé automatiquement si quantité × prix change"
        oi.input :delivery_status, as: :select, collection: OrderItem.delivery_statuses.keys.map { |status| [ status.humanize, status ] }
      end
    end

    f.actions
  end
end
