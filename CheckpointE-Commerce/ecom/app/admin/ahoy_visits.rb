# frozen_string_literal: true

ActiveAdmin.register Ahoy::Visit, as: "AhoyVisit" do
  menu priority: 4, label: "👥 Visites"

  # For security, limit the actions that should be available
  actions :all, except: [ :new, :edit, :destroy ]

  # Add or remove filters to toggle their visibility
  filter :id
  filter :visit_token
  filter :visitor_token
  filter :user_type
  filter :user_id
  filter :started_at
  filter :ip
  filter :user_agent
  filter :referrer
  filter :referring_domain
  filter :landing_page
  filter :browser
  filter :os
  filter :device_type
  filter :country
  filter :region
  filter :city
  filter :utm_source
  filter :utm_medium
  filter :utm_term
  filter :utm_content
  filter :utm_campaign
  filter :created_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :visit_token do |visit|
      truncate(visit.visit_token, length: 20) if visit.visit_token
    end
    column :visitor_token do |visit|
      truncate(visit.visitor_token, length: 20)
    end
    column :started_at
    column :user do |visit|
      if visit.user
        case visit.user_type
        when "User"
          link_to visit.user.full_name, admin_user_path(visit.user)
        when "Vendor"
          link_to visit.user.name, admin_vendor_path(visit.user)
        else
          "#{visit.user_type} ##{visit.user_id}"
        end
      end
    end
    column :ip
    column :browser
    column :device_type
    column :country
    column :city
    column :utm_source
    column "Événements" do |visit|
      visit.events.count
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :visit_token
      row :visitor_token
      row :started_at
      row :user_type
      row :user do |visit|
        if visit.user
          case visit.user_type
          when "User"
            link_to visit.user.full_name, admin_user_path(visit.user)
          when "Vendor"
            link_to visit.user.name, admin_vendor_path(visit.user)
          else
            "#{visit.user_type} ##{visit.user_id}"
          end
        end
      end
      row :ip
      row :user_agent
      row :referrer
      row :referring_domain
      row :landing_page
      row :browser
      row :os
      row :device_type
      row :country
      row :region
      row :city
      row :latitude
      row :longitude
      row :utm_source
      row :utm_medium
      row :utm_term
      row :utm_content
      row :utm_campaign
      row :created_at
      row :updated_at
    end

    panel "Événements associés (#{resource.events.count})" do
      table_for resource.events.order(time: :desc).limit(50) do
        column :id
        column :name do |event|
          status_tag event.name, class: event.name.parameterize
        end
        column :time
        column :shop do |event|
          link_to event.shop.name, admin_shop_path(event.shop) if event.shop
        end
        column :item do |event|
          link_to event.item.name, admin_item_path(event.item) if event.item
        end
        column :actions do |event|
          link_to "Voir", admin_ahoy_event_path(event), class: "button"
        end
      end
      if resource.events.count > 50
        para "Affichage des 50 premiers événements sur #{resource.events.count} au total",
             class: "text-sm text-gray-500"
      end
    end
  end

  # Scope pour filtrer les visites récentes
  scope :all, default: true
  scope :recent, -> { where("started_at >= ?", 7.days.ago) }
  scope :today, -> { where("started_at >= ?", Date.today.beginning_of_day) }

  controller do
    def scoped_collection
      super.includes(:user, :events)
    end
  end
end
