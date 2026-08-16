Rails.application.routes.draw do
  # Sessions admin (login/logout) — chemins attendus par ActiveAdmin
  get "admin_user/sign_in", to: "admin/sessions#new", as: :new_admin_user_session
  post "admin_user/sign_in", to: "admin/sessions#create"
  delete "admin_user/sign_out", to: "admin/sessions#destroy", as: :destroy_admin_user_session

  # ─────────────────────────────────────────
  # Custom admin dashboards (standalone Rails MVC)
  # ─────────────────────────────────────────
  get "/admin/hub",           to: "admin/dashboards#index",     as: :admin_hub
  get "/admin/hub/analytics", to: "admin/dashboards#analytics", as: :admin_hub_analytics
  get "/admin/hub/finance",   to: "admin/dashboards#finance",   as: :admin_hub_finance

  ActiveAdmin.routes(self)

  # Mission Control Jobs - Dashboard for Active Job
  mount MissionControl::Jobs::Engine, at: "/mission_control/jobs"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # LAM delivery status callback (no locale)
  get "sms/lam_callback", to: "sms/lam_callbacks#delivery"
  post "sms/lam_callback", to: "sms/lam_callbacks#delivery"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  scope "(:locale)", locale: /fr|en/ do
    # Defines the root path route ("/")
    # root "posts#index"
    root "pages#home"

    # Page "arrive bientôt" — utilisée pour rediriger les liens / sections pas encore livrés.
    get "soon", to: "pages#coming_soon", as: :coming_soon

    resources :passwords, param: :token
    resources :users, only: [ :new, :create ]

    # Newsletter subscription
    resources :newsletter_subscribers, only: [ :create ]

    # ============================================
    # Routes publiques SEO-friendly (AVANT namespace :client)
    # ============================================

    # Catégories (multilingue - même chemin dans les deux langues)
    get "categories/:slug", to: "categories#show", as: :category
    get "categories/:category_slug/:sub_category_slug", to: "categories#sub_category", as: :category_sub_category

    # Produits (multilingue - chemins différents selon la langue)
    constraints locale: /fr/ do
      get "produits", to: "items#index", as: :produits
      get "produits/:id", to: "items#show", as: :produit
    end

    constraints locale: /en/ do
      get "products", to: "items#index", as: :products
      get "products/:id", to: "items#show", as: :product
    end

    # Boutiques (multilingue - chemins différents selon la langue)
    constraints locale: /fr/ do
      get "boutiques", to: "shops#index", as: :boutiques
      get "boutiques/:slug", to: "shops#show", as: :boutique
    end

    constraints locale: /en/ do
      get "shops", to: "shops#index", as: :shops
      get "shops/:slug", to: "shops#show", as: :shop
    end

    # Recherche autocomplete (suggestions JSON)
    get "search/suggestions", to: "search#suggestions", as: :search_suggestions, defaults: { format: :json }

    # Routes pour les employés
    namespace :employees do
      # Authentification
      resource :session, only: [ :new, :create, :destroy ]
      get "login", to: "sessions#new", as: :login
      delete "logout", to: "sessions#destroy", as: :logout

      # Dashboard
      get "dashboard", to: "dashboards#show", as: :dashboard
      root to: "dashboards#show"

      # Analytics par boutique
      resources :shops, only: [] do
        get "analytics", to: "analytics#index", as: :analytics
      end

      # Commandes
      resources :orders, only: [ :index, :show ] do
        member do
          patch :update_status
          patch :update_item_delivery_status
        end
      end

      # Catalogue : miroir complet du portail vendor — index/show/CRUD/import en masse/variantes,
      # dans les URLs employees_*. La gating fonctionnelle (managers seuls peuvent créer/éditer)
      # est faite via current_employee.can_manage_items?.
      resources :items, only: [ :index, :new, :create, :show, :edit, :update ] do
        member do
          delete :purge_image
          post :generate_variants
          post :retry_ai_enrichment
          get :manage
        end
        collection do
          post :generate_ai_preview
          get :download_template
          get :download_categories
          post :bulk_upload
        end
        resources :variants, only: [ :index, :new, :create, :edit, :update, :destroy ], controller: "item_variants"
      end

      # Clients (lecture seule, parité visuelle avec le portail vendor)
      resources :clients, only: [ :index, :show ]

      # Finances : miroir vendor (index + transactions + payouts + détail payout)
      resources :finances, only: [ :index ], controller: "finances" do
        collection do
          get :transactions
          get :payouts
        end
      end
      get "finances/payouts/:id", to: "finances#show_payout", as: :finances_payout
    end

    namespace :vendors do
      # Gestion des employés
      resources :employees do
        member do
          patch :toggle_status
        end
      end
      resource :registration, only: [ :new, :create ], controller: "registrations"
      resource :session, only: [ :new, :create, :destroy ], controller: "sessions"
      resource :verification, only: [ :new, :create, :show ], controller: "verifications" do
        post :resend, on: :collection
      end
      resource :shop, only: [ :new, :create ], controller: "shops"
      resource :plan, only: [ :new, :create ], controller: "plans"

      # Paiement des abonnements via Paydunya
      get "paydunya/subscription_success", to: "paydunya_callbacks#subscription_success", as: :paydunya_subscription_success
      get "paydunya/subscription_cancel", to: "paydunya_callbacks#subscription_cancel", as: :paydunya_subscription_cancel
      post "paydunya/subscription_ipn", to: "paydunya_callbacks#ipn", as: :paydunya_subscription_ipn

      resources :shops, only: [ :edit, :update ], controller: "shops" do
        member do
          # Analytics pour chaque boutique
          get "analytics", to: "analytics#index", as: :analytics
          delete :destroy_logo
        end
      end
      resource :dashboard, only: [ :show ], controller: "dashboards"
      resource :account, only: [ :show, :edit, :update ], controller: "accounts" do
        get :confirm_change
        patch :confirm_change
        post :resend_change_code
      end
      resources :items, only: [ :index, :new, :create, :show, :edit, :update ] do
        member do
          delete :purge_image
          post :generate_variants
          post :retry_ai_enrichment
          get :manage
        end
        collection do
          post :generate_ai_preview
          get :download_template
          get :download_categories
          post :bulk_upload
        end
        resources :variants, only: [ :index, :new, :create, :edit, :update, :destroy ], controller: "item_variants"
      end
      resources :orders, only: [ :index, :show ] do
        collection do
          patch :update_item_delivery_status
          post :upgrade_plan
        end
      end
      resources :clients, only: [ :index, :show ]

      # Palette de couleurs de la boutique (privée)
      resources :colors, only: [ :index, :new, :create, :edit, :update ], controller: "shop_colors" do
        member do
          patch :archive
          patch :restore
        end
      end
      resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]

      # Finances
      resources :finances, only: [ :index ], controller: "finances" do
        collection do
          get :transactions
          get :payouts
        end
      end

      # Route séparée pour les détails d'un payout
      get "finances/payouts/:id", to: "finances#show_payout", as: :finances_payout
    end

    namespace :client do
      # Dashboard
      resource :dashboard, only: [ :show ]

      # Compte utilisateur
      resource :account, only: [ :show, :edit, :update ]

      # Authentification
      resource :registration, only: [ :new, :create ]
      resource :verification, only: [ :new, :create ], controller: "verifications" do
        post :resend, on: :collection
      end
      resource :session, only: [ :new, :create, :destroy ]

      # Mot de passe oublié - flux 3 étapes (SMS-first) :
      # 1. saisie téléphone        → SMS OTP court (POST /passwords)
      # 2. saisie OTP              → vérification + reset_token signé en session (POST /passwords/verify)
      # 3. saisie nouveau mdp      → mise à jour + reconnexion (PATCH /passwords)
      get   "passwords/new",     to: "passwords#new",       as: :new_password
      post  "passwords",         to: "passwords#create",    as: :passwords
      get   "passwords/verify",  to: "passwords#verify",    as: :verify_password
      post  "passwords/verify",  to: "passwords#check_otp"
      get   "passwords/edit",    to: "passwords#edit",      as: :edit_password
      patch "passwords",         to: "passwords#update"

      # Catalogue
      resources :items, only: [ :index, :show ] do
        collection do
          get :recommendations
        end
      end

      # Boutiques / Pages de marques
      resources :shops, only: [ :index, :show ], param: :slug do
        collection do
          get "officielles", to: "shops#official", as: :official
          get "locales", to: "shops#local", as: :local
        end
      end

      # Panier
      resource :cart, only: [ :show ] do
        delete :clear, on: :collection
      end
      resources :cart_items, only: [ :create, :update, :destroy ]

      # Adresses
      resources :addresses do
        patch :set_default, on: :member
      end

      # Commandes
      resources :orders, only: [ :index, :show, :new, :create ] do
        collection do
          get :get_delivery_slots
        end
      end

      # Avis clients
      resources :reviews, only: [ :index, :create, :update, :destroy ] do
        member do
          post :mark_as_helpful
        end
        collection do
          get :my_reviews
        end
      end
    end

    # PayDunya Callbacks
    get "paydunya/success", to: "paydunya_callbacks#success", as: :paydunya_success
    get "paydunya/cancel", to: "paydunya_callbacks#cancel", as: :paydunya_cancel
    post "paydunya/ipn", to: "paydunya_callbacks#ipn", as: :paydunya_ipn
    post "paydunya/charge", to: "paydunya_callbacks#charge", as: :paydunya_charge

    # Pages légales et statiques
    get "devenir-vendeur", to: "pages#become_vendor", as: :become_vendor
    get "conditions-utilisation", to: "pages#terms", as: :terms
    get "politique-confidentialite", to: "pages#privacy", as: :privacy

    # Pages éditoriales (À propos, Contact, Blog) — slug FR par défaut, identique en EN
    get  "a-propos", to: "pages#about",          as: :about
    get  "contact",  to: "pages#contact",        as: :contact
    post "contact",  to: "pages#contact_create", as: :contact_create

    # Blog public
    get "blog",                       to: "blog_posts#index",    as: :blog
    get "blog/categorie/:slug",       to: "blog_posts#category", as: :blog_category
    get "blog/:id",                   to: "blog_posts#show",     as: :blog_post

    # Page de maintenance
    get "maintenance", to: "maintenance#show", as: :maintenance
    post "maintenance", to: "maintenance#create"
    get "maintenance/confirmation", to: "maintenance#confirmation", as: :maintenance_confirmation
  end
end
