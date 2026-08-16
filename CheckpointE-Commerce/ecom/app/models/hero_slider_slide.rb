class HeroSliderSlide < ApplicationRecord
  belongs_to :home_page_section

  has_one_attached :image
  has_one_attached :image_tablet
  has_one_attached :image_mobile

  # Méthodes pour retourner les chemins d'assets statiques
  # Utilisées par la vue pour afficher bg_image
  def bg_image
    # D'abord, chercher dans les settings de la section
    setting = home_page_section.home_page_section_settings.find_by(key: "hero_slide_#{position}_bg_image")
    return setting.value if setting&.value.present?

    # Sinon, retourner le chemin d'asset statique basé sur la position (fallback)
    case position
    when 1
      "storefront/banners/hero-bg-samsung.jpg"
    when 2, 3
      "storefront/banners/hero-bg.jpg"
    else
      nil
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "badge_bg_color", "badge_text", "badge_text_color", "created_at", "cta_link", "cta_text", "gradient", "home_page_section_id", "id", "position", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "home_page_section" ]
  end
end
