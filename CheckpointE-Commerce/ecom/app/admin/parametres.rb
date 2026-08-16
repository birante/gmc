# frozen_string_literal: true

# Page de menu parent pour organiser les paramètres système
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Paramètres Système" do
  menu priority: 11, label: "⚙️ Paramètres Système"

  content title: "Paramètres Système" do
    para "Configuration des devises, méthodes de paiement et intégrations",
         class: "blank_slate_container",
         id: "dashboard_default_message"
  end
end
