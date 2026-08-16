module ShopsHelper
  # Retourne la couleur primaire de la boutique ou une couleur par défaut
  def shop_primary_color(shop)
    shop&.primary_color.presence || "#551694"
  end

  # Retourne la couleur secondaire de la boutique ou une couleur par défaut
  def shop_secondary_color(shop)
    shop&.secondary_color.presence || "#8B5CF6"
  end

  # Retourne les deux couleurs sous forme de hash
  def shop_colors(shop)
    {
      primary: shop_primary_color(shop),
      secondary: shop_secondary_color(shop)
    }
  end

  # Génère un style CSS pour un gradient utilisant les couleurs de la boutique
  def shop_gradient_style(shop, direction: "to-r")
    primary = shop_primary_color(shop)
    secondary = shop_secondary_color(shop)
    "background: linear-gradient(#{direction}, #{primary}, #{secondary});"
  end

  # Génère une classe Tailwind pour le gradient (si les couleurs sont personnalisées)
  def shop_gradient_class(shop)
    return "bg-gradient-to-r from-[#551694] to-[#8B5CF6]" unless shop&.primary_color.present? && shop&.secondary_color.present?

    primary = shop.primary_color
    secondary = shop.secondary_color
    "bg-gradient-to-r from-[#{primary}] to-[#{secondary}]"
  end
end
