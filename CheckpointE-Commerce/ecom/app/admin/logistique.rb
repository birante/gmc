# frozen_string_literal: true

# Page de menu parent pour organiser la logistique
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Logistique" do
  menu priority: 8, label: "🚚 Logistique"

  content title: "Logistique" do
    para "Gestion des zones, prix et créneaux de livraison",
         class: "blank_slate_container",
         id: "dashboard_default_message"
  end
end
