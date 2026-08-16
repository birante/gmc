# frozen_string_literal: true

class MigrateShopPageHeadersToSlides < ActiveRecord::Migration[8.0]
  def up
    return unless table_exists?(:shop_page_headers)
    return unless defined?(ShopPageHeader) && defined?(ShopPageHeaderSlide)

    ShopPageHeader.find_each do |header|
      next unless header.shop_id.present?

      slide = ShopPageHeaderSlide.create!(
        shop_id: header.shop_id,
        link: header.link,
        button_text: header.button_text,
        position: 1
      )
      # Copier l'image Active Storage si présente
      if header.image.attached?
        slide.image.attach(header.image.blob)
      end
    rescue StandardError => e
      Rails.logger.warn "Migration shop_page_header #{header&.id}: #{e.message}"
    end
  end

  def down
    # Pas de rollback - les slides restent
  end
end
