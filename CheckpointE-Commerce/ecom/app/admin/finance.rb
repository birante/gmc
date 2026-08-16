# frozen_string_literal: true

# Page de menu parent pour organiser le module Finance
# Cette page sert uniquement à créer un menu parent
ActiveAdmin.register_page "Finance" do
  menu priority: 6, label: "💰 Finance"

  content title: "Finance" do
    para "Module Finance - Gestion des revenus, commissions, abonnements et reversements",
         class: "blank_slate_container",
         id: "dashboard_default_message"

    div class: "mt-6" do
      h3 "Accès rapide", class: "text-lg font-semibold mb-4"
      div class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4" do
        link_to admin_finance_dashboard_path, class: "bg-white dark:bg-gray-800 rounded-lg shadow p-4 hover:shadow-md transition" do
          div class: "text-2xl mb-2" do
            "📊"
          end
          div class: "font-semibold text-gray-900 dark:text-white" do
            "Dashboard"
          end
          div class: "text-sm text-gray-500 dark:text-gray-400" do
            "Vue d'ensemble et statistiques"
          end
        end

        link_to admin_payouts_path, class: "bg-white dark:bg-gray-800 rounded-lg shadow p-4 hover:shadow-md transition" do
          div class: "text-2xl mb-2" do
            "💳"
          end
          div class: "font-semibold text-gray-900 dark:text-white" do
            "Paiements Vendeurs"
          end
          div class: "text-sm text-gray-500 dark:text-gray-400" do
            "Gestion des reversements"
          end
        end

        link_to admin_payments_path, class: "bg-white dark:bg-gray-800 rounded-lg shadow p-4 hover:shadow-md transition" do
          div class: "text-2xl mb-2" do
            "💵"
          end
          div class: "font-semibold text-gray-900 dark:text-white" do
            "Paiements Clients"
          end
          div class: "text-sm text-gray-500 dark:text-gray-400" do
            "Historique des paiements"
          end
        end

        link_to admin_shop_transactions_path, class: "bg-white dark:bg-gray-800 rounded-lg shadow p-4 hover:shadow-md transition" do
          div class: "text-2xl mb-2" do
            "📊"
          end
          div class: "font-semibold text-gray-900 dark:text-white" do
            "Transactions"
          end
          div class: "text-sm text-gray-500 dark:text-gray-400" do
            "Traçabilité complète"
          end
        end
      end
    end
  end
end
