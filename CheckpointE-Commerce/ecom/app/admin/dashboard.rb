# frozen_string_literal: true

# Dashboard Active Admin minimal — redirige vers le Hub standalone
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "🚀 Hub Admin"

  controller do
    def index
      redirect_to main_app.admin_hub_path
    end
  end

  content title: "Hub Admin" do
    # redirection automatique côté contrôleur
  end
end
