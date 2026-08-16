# frozen_string_literal: true

# Page de menu parent pour organiser le contenu de la page d'accueil
# Cette page n'est pas accessible directement, elle sert uniquement à créer un menu parent
ActiveAdmin.register_page "Page d'accueil" do
  menu priority: 7, label: "🏠 Page d'accueil"

  content title: "Page d'accueil" do
    para "Gestion du contenu de la page d'accueil", class: "blank_slate_container", id: "dashboard_default_message"
  end
end
