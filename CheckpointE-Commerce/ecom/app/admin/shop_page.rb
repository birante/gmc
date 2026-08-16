# frozen_string_literal: true

# Page de menu parent pour organiser le contenu de la page boutique
ActiveAdmin.register_page "Page Boutique" do
  menu priority: 8, label: "🏪 Page Boutique"

  content title: "Page Boutique" do
    para "Gestion du contenu des pages boutiques (header, sections, produits, catégories). Chaque boutique peut avoir un header personnalisé (photo + lien + bouton) et des sections ordonnées avec produits et catégories sélectionnables.", class: "blank_slate_container", id: "dashboard_default_message"
  end
end
