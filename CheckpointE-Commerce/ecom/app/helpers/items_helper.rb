# frozen_string_literal: true

module ItemsHelper
  COLOR_HEX_MAP = {
    "noir" => "#000000",
    "blanc" => "#FFFFFF",
    "rouge" => "#DC2626",
    "bleu" => "#1D4ED8",
    "bleu marine" => "#0F172A",
    "bleu ciel" => "#38BDF8",
    "bleu pétrole" => "#1E5F74",
    "vert" => "#16A34A",
    "vert kaki" => "#5B6630",
    "jaune" => "#FACC15",
    "rose" => "#EC4899",
    "orange" => "#F97316",
    "violet" => "#7C3AED",
    "gris" => "#6B7280",
    "gris clair" => "#D1D5DB",
    "gris foncé" => "#374151",
    "argent" => "#C0C0C0",
    "or" => "#D4AF37",
    "marron" => "#78350F",
    "beige" => "#E7D7B5",
    "kaki" => "#7B7B3F",
    "turquoise" => "#14B8A6",
    "midnight" => "#1A1A2E",
    "sky blue" => "#87CEEB",
    "starlight" => "#F5F5DC"
  }.freeze

  COLOR_ATTRIBUTE_NAMES = %w[Couleur Color Couleurs Colors].freeze

  # Renvoie le code hex correspondant à une couleur.
  # Accepte un Hash (payload variant), un AttributeValue, ou une string.
  # Priorité : hex_code explicite (palette boutique) → dictionnaire → gris clair.
  def color_hex_for(value)
    return "#CCCCCC" if value.blank?

    explicit = case value
    when Hash
      value[:hex_code] || value["hex_code"]
    when AttributeValue
      value.hex_code
    end
    return explicit if explicit.present?

    name = value.is_a?(Hash) ? (value[:value] || value["value"]) :
           value.is_a?(AttributeValue) ? value.value : value
    return "#CCCCCC" if name.blank?
    COLOR_HEX_MAP[name.to_s.strip.downcase] || "#CCCCCC"
  end

  # True si l'attribut est sémantiquement une couleur (rendu en swatch).
  def color_attribute?(name)
    return false if name.blank?
    normalized = name.to_s.strip.downcase
    COLOR_ATTRIBUTE_NAMES.map(&:downcase).include?(normalized)
  end

  # Renvoie une classe utilitaire de contraste (border foncée si swatch très clair).
  def swatch_needs_dark_border?(hex)
    return true if hex.blank?
    rgb = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
    return true if rgb.size < 3
    brightness = (rgb[0] * 299 + rgb[1] * 587 + rgb[2] * 114) / 1000.0
    brightness > 230
  end

  # Renvoie les valeurs d'attribut « couleur » distinctes disponibles pour un item,
  # utilisées pour afficher un mini rang de pastilles sur les cartes produit.
  def color_values_for(item)
    return [] unless item&.respond_to?(:item_attributes)
    color_attr = item.item_attributes.find { |a| color_attribute?(a.name) }
    return [] unless color_attr
    color_attr.attribute_values.sort_by { |av| av.position || 0 }
  end
end
