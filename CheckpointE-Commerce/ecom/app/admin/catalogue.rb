# frozen_string_literal: true

# Page de menu parent pour organiser le catalogue
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Catalogue" do
  menu priority: 4, label: "📦 Catalogue"

  content title: "Catalogue" do
    para "Gestion du catalogue de produits", class: "blank_slate_container", id: "dashboard_default_message"
  end
end
