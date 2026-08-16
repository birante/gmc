class ShopSpotlight < ApplicationRecord
  belongs_to :home_page_section
  belongs_to :shop

  has_one_attached :promo_image

  validates :shop, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :slogan, length: { maximum: 500 }
  validates :promo_title, length: { maximum: 100 }
  validates :promo_subtitle, length: { maximum: 200 }

  scope :ordered, -> { order(position: :asc) }

  # Parse les IDs de produits depuis le champ item_ids
  def item_ids_array
    return [] if item_ids.blank?

    item_ids.split(/[\s,;]+/)
            .map(&:strip)
            .reject(&:blank?)
            .map(&:to_i)
            .reject(&:zero?)
            .uniq
  end

  # Récupère les produits associés avec eager loading optimal
  def items
    return [] if item_ids_array.empty?

    @items ||= begin
      items = Item.available_for_sale
                  .where(id: item_ids_array, shop_id: shop_id)
                  .includes(
                    :shop,
                    :currency,
                    variants: [],
                    main_image_attachment: :blob
                  )
                  .to_a

      # Trier selon l'ordre défini dans item_ids
      items.sort_by { |item| item_ids_array.index(item.id) }
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "home_page_section_id", "shop_id", "slogan", "position", "promo_title", "promo_subtitle", "item_ids", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section", "shop", "promo_image_attachment", "promo_image_blob" ]
  end
end
