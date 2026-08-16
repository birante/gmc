# frozen_string_literal: true

ActiveAdmin.register Ahoy::Event, as: "AhoyEvent" do
  menu priority: 3, label: "📊 Événements"

  # For security, limit the actions that should be available
  actions :all, except: [ :new, :edit, :destroy ]

  # Add or remove filters to toggle their visibility
  filter :id
  filter :name, as: :select, collection: -> { Ahoy::Event.distinct.pluck(:name).compact.sort }
  filter :time
  filter :visit
  filter :user_type
  filter :user_id
  filter :shop
  filter :item

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :name do |event|
      status_tag event.name, class: event.name.parameterize
    end
    column :time
    column :visit do |event|
      link_to "Visit ##{event.visit_id}", admin_ahoy_visit_path(event.visit) if event.visit
    end
    column :user do |event|
      if event.user
        case event.user_type
        when "User"
          link_to event.user.full_name, admin_user_path(event.user)
        when "Vendor"
          link_to event.user.name, admin_vendor_path(event.user)
        else
          "#{event.user_type} ##{event.user_id}"
        end
      end
    end
    column :shop do |event|
      link_to event.shop.name, admin_shop_path(event.shop) if event.shop
    end
    column :item do |event|
      link_to event.item.name, admin_item_path(event.item) if event.item
    end
    column :properties do |event|
      if event.properties.present?
        truncate(event.properties.to_json, length: 100)
      end
    end
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :name do |event|
        status_tag event.name, class: event.name.parameterize
      end
      row :time
      row :visit do |event|
        link_to "Visit ##{event.visit_id}", admin_ahoy_visit_path(event.visit) if event.visit
      end
      row :user_type
      row :user do |event|
        if event.user
          case event.user_type
          when "User"
            link_to event.user.full_name, admin_user_path(event.user)
          when "Vendor"
            link_to event.user.name, admin_vendor_path(event.user)
          else
            "#{event.user_type} ##{event.user_id}"
          end
        end
      end
      row :shop do |event|
        link_to event.shop.name, admin_shop_path(event.shop) if event.shop
      end
      row :item do |event|
        link_to event.item.name, admin_item_path(event.item) if event.item
      end
      row :properties do |event|
        if event.properties.present?
          pre JSON.pretty_generate(event.properties)
        else
          "Aucune propriété"
        end
      end
    end
  end

  # Scope pour filtrer par type d'événement
  scope :all, default: true
  scope :page_views
  scope :shop_views
  scope :item_views
  scope :cart_actions
  scope :orders

  controller do
    def scoped_collection
      super.includes(:visit, :user, :shop, :item)
    end
  end
end
