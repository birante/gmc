class SiteSetting < ApplicationRecord
  KINDS = %w[text textarea].freeze

  validates :key, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }

  scope :ordered, -> { order(:position, :key) }

  # Renvoie la valeur configurée pour la locale demandée, ou nil si vide.
  # Utiliser via le helper `site_seo` côté vues — qui gère le fallback I18n.
  def self.get(key, locale: I18n.locale)
    return nil unless table_exists?

    setting = find_by(key: key.to_s)
    return nil unless setting

    setting.value_for(locale)
  end

  def value_for(locale)
    raw = locale.to_s.start_with?("en") ? value_en : value_fr
    raw.presence
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id key label kind position created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
