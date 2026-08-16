# frozen_string_literal: true

# Page de menu parent pour organiser les plans et règles
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Plans & Règles" do
  menu priority: 10, label: "⚙️ Plans & Règles"

  content title: "Plans & Règles" do
    para "Gestion des plans et règles", class: "blank_slate_container", id: "dashboard_default_message"
  end
end
