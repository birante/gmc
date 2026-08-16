# frozen_string_literal: true

# Query pour lire les items disponibles au public
#
# Usage:
#   query = PublicItemsQuery.new
#   items = query.available_for_sale
#   shops = query.shops_for_items(items)
class PublicItemsQuery
  def available_for_sale
    Item.available_for_sale
        .includes(:shop, :product_sub_category, :currency, :variants)
        .with_attached_main_image
        .with_attached_images
        .joins("LEFT JOIN item_variants ON item_variants.item_id = items.id AND item_variants.is_default = true")
  end

  def by_sub_category_ids(sub_category_ids)
    available_for_sale.where(product_sub_category_id: sub_category_ids)
  end

  def by_sub_category(sub_category)
    available_for_sale.where(product_sub_category_id: sub_category.id)
  end

  def find_by_slug(slug)
    Item.available_for_sale
        .includes(
          :shop,
          :product_sub_category,
          :currency,
          :reviews,
          variants: { attribute_values: :item_attribute },
          main_image_attachment: :blob,
          images_attachments: :blob
        )
        .friendly.find(slug)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def shop_items_for_item(item, exclude_item_id: nil, limit: 12)
    scope = item.shop.items.available_for_sale
    scope = scope.where.not(id: exclude_item_id) if exclude_item_id
    scope.includes(:variants, :currency)
         .with_attached_main_image
         .with_attached_images
         .order(created_at: :desc)
         .limit(limit)
         .to_a
  end

  def shops_for_items(items)
    Shop.joins(:items)
        .where(items: { id: items.select(:id) })
        .distinct
        .order(:name)
        .limit(20)
  end
end
