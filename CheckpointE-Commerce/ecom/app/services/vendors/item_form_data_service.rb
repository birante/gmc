# frozen_string_literal: true

module Vendors
  class ItemFormDataService
    def initialize(vendor:, shop: nil)
      @vendor = vendor
      @shop = shop
    end

    def call
      {
        product_categories: load_product_categories,
        currencies: load_currencies,
        delivery_categories: load_delivery_categories,
        product_attributes: load_product_attributes,
        categories_json: build_categories_json
      }
    end

    private

    attr_reader :vendor, :shop

    def load_product_categories
      ProductCategory.where(is_active: true).includes(:sub_categories)
    end

    def load_currencies
      Currency.active
    end

    def load_delivery_categories
      DeliveryCategory.all.order(:name)
    end

    def load_product_attributes
      ProductAttribute.active.includes(:product_attribute_values).ordered
    end

    def build_categories_json
      load_product_categories.map do |cat|
        {
          id: cat.id,
          name: cat.name,
          sub_categories: cat.sub_categories.where(is_active: true).map { |sub| { id: sub.id, name: sub.name } }
        }
      end.to_json
    end
  end
end
