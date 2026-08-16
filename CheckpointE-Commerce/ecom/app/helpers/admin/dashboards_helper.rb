# frozen_string_literal: true

module Admin::DashboardsHelper
  # Vérifie si on est sur le contrôleur/action donné (utilisé pour la sidebar active)
  def controller_action?(controller_sym, action_sym)
    controller_name.to_sym == controller_sym && action_name.to_sym == action_sym
  end

  # Badge de tendance (↑ vert / ↓ rouge)
  def trend_badge(curr, prev)
    return "" if prev.nil? || prev.zero?
    pct = ((curr.to_f - prev.to_f) / prev.to_f * 100).round(1)
    ok  = pct >= 0
    css = ok ? "stat-badge-up" : "stat-badge-down"
    ico = ok ? "↑" : "↓"
    content_tag(:span, "#{ico} #{pct.abs}%", class: css)
  end

  # Libellés statuts commandes (méthode pour être accessible dans les vues ERB)
  def hub_status_labels
    {
      "pending"          => "En attente",
      "processing"       => "En traitement",
      "shipped"          => "Expédié",
      "partial_delivery" => "Livraison partielle",
      "delivered"        => "Livré",
      "canceled"         => "Annulé"
    }
  end

  def hub_status_badge(status)
    colors = {
      "pending"          => "bg-amber-100 text-amber-700",
      "processing"       => "bg-blue-100 text-blue-700",
      "shipped"          => "bg-indigo-100 text-indigo-700",
      "partial_delivery" => "bg-orange-100 text-orange-700",
      "delivered"        => "bg-green-100 text-green-700",
      "canceled"         => "bg-red-100 text-red-700"
    }
    label = hub_status_labels[status.to_s] || status.to_s.humanize
    css   = colors[status.to_s] || "bg-gray-100 text-gray-700"
    content_tag(:span, label, class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{css}")
  end
end
