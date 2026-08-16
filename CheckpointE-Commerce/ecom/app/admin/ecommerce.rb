# frozen_string_literal: true

# Page de menu parent pour organiser le module E-Commerce
ActiveAdmin.register_page "E-Commerce" do
  menu priority: 3, label: "🛍️ E-Commerce"

  content title: "E-Commerce" do
    para "Gestion des commandes, paniers et transactions",
         class: "blank_slate_container",
         id: "dashboard_default_message"
  end
end
