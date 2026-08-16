# frozen_string_literal: true

# Query pour lire les items d'un vendor avec filtres
#
# Usage:
#   query = VendorItemsQuery.new(vendor: vendor, shop_condition: condition, shop_value: value)
#   items = query.search(filters: { search: "test", validation_status: "approved" })
#   items = query.search(filters: params, paginate: true)
#
# Examples:
#   # Recherche simple
#   items = query.search(filters: { search: "chaussures" })
#
#   # Avec filtres multiples et pagination
#   items = query.search(filters: { search: "chaussures", validation_status: "approved" }, paginate: true)
class VendorItemsQuery
  def initialize(vendor:, shop_condition:, shop_value:)
    @vendor = vendor
    @shop_condition = shop_condition
    @shop_value = shop_value
  end

  def search(filters: {}, paginate: false)
    items = base_scope

    items = apply_search(items, filters[:search]) if filters[:search].present?
    items = apply_validation_status_filter(items, filters[:validation_status]) if filters[:validation_status].present?
    items = apply_pagination(items, filters[:page], filters[:per_page]) if paginate

    items
  end

  def call(filters: {}, paginate: false)
    # Alias pour compatibilité
    search(filters: filters, paginate: paginate)
  end

  private

  attr_reader :vendor, :shop_condition, :shop_value

  def base_scope
    Item.joins(:shop)
        .where(@shop_condition, @shop_value)
        .includes(:product_sub_category, :currency, :shop, :variants, :main_image_attachment, :images_attachments)
        .order(created_at: :desc)
  end

  def apply_search(items, search_term)
    term = "%#{search_term.strip}%"
    items.where("items.name ILIKE ? OR items.description ILIKE ?", term, term)
  end

  def apply_validation_status_filter(items, status)
    items.where(validation_status: status)
  end

  def apply_pagination(items, page, per_page)
    return items unless defined?(Kaminari)

    items.page(page).per(per_page || 20)
  end
end
