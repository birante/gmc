# frozen_string_literal: true

# Query pour lire les commandes d'un client avec filtres
#
# Usage:
#   query = ClientOrdersQuery.new(user: user)
#   orders = query.call(filters: { status: 'pending' })
class ClientOrdersQuery
  def initialize(user:)
    @user = user
  end

  def call(filters: {})
    orders = base_scope

    if filters[:status].present? && filters[:status] != "all"
      case filters[:status]
      when "in_progress"
        orders = orders.where(status: [ "pending", "processing", "shipped" ])
      when "delivered"
        orders = orders.where(status: "delivered")
      end
    end

    orders
  end

  private

  attr_reader :user

  def base_scope
    user.orders
        .includes(
          order_items: {
            item: [ :product_sub_category, { main_image_attachment: :blob } ],
            item_variant: [ :item, { attribute_values: :item_attribute } ],
            shop: { logo_attachment: :blob }
          },
          delivery_zone: {},
          delivery_slot: {}
        )
        .order(created_at: :desc)
  end
end
