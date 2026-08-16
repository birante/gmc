# frozen_string_literal: true

# Page de menu parent pour organiser les boutiques et vendeurs
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Boutiques & Vendeurs" do
  menu priority: 5, label: "🏪 Boutiques & Vendeurs"

  content title: "Boutiques & Vendeurs" do
    para "Gestion des boutiques, vendeurs et employés",
         class: "blank_slate_container",
         id: "dashboard_default_message"
  end
end
