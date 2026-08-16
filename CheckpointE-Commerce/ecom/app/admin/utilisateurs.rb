# frozen_string_literal: true

# Page de menu parent pour organiser les utilisateurs
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Utilisateurs" do
  menu priority: 9, label: "👥 Utilisateurs"

  content title: "Utilisateurs" do
    para "Gestion des clients, vérifications et adresses",
         class: "blank_slate_container",
         id: "dashboard_default_message"
  end
end
