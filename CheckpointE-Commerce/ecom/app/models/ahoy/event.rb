# frozen_string_literal: true

module Ahoy
  class Event < ApplicationRecord
    include Ahoy::QueryMethods

    self.table_name = "ahoy_events"

    belongs_to :visit, optional: true
    belongs_to :user, polymorphic: true, optional: true
    belongs_to :shop, optional: true
    belongs_to :item, optional: true

    # Scopes pour faciliter les requêtes
    scope :page_views, -> { where(name: "page_viewed") }
    scope :shop_views, -> { where(name: "shop_viewed") }
    scope :item_views, -> { where(name: "item_viewed") }
    scope :cart_actions, -> { where(name: [ "item_added_to_cart", "item_removed_from_cart" ]) }
    scope :orders, -> { where(name: "order_completed") }

    scope :for_shop, ->(shop_id) { where(shop_id: shop_id) }
    scope :for_item, ->(item_id) { where(item_id: item_id) }

    scope :in_period, ->(start_date, end_date) {
      where(time: start_date.beginning_of_day..end_date.end_of_day)
    }

    scope :recent, ->(days = 7) {
      where("time >= ?", days.days.ago)
    }

    def self.ransackable_attributes(_auth_object = nil)
      %w[id visit_id user_type user_id name properties time shop_id item_id]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[visit user shop item]
    end
  end
end
