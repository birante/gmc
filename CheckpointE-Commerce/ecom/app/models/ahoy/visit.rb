# frozen_string_literal: true

module Ahoy
  class Visit < ApplicationRecord
    self.table_name = "ahoy_visits"

    has_many :events, class_name: "Ahoy::Event", dependent: :destroy
    belongs_to :user, polymorphic: true, optional: true

    # Scopes for filtering visits
    scope :recent, -> { where("started_at >= ?", 7.days.ago) }
    scope :today, -> { where("started_at >= ?", Date.today.beginning_of_day) }

    def self.ransackable_attributes(_auth_object = nil)
      %w[id visit_token visitor_token user_type user_id started_at ip user_agent referrer referring_domain landing_page browser os device_type country region city latitude longitude utm_source utm_medium utm_term utm_content utm_campaign created_at updated_at]
    end

    def self.ransackable_associations(_auth_object = nil)
      %w[events user]
    end
  end
end
