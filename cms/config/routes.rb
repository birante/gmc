Rails.application.routes.draw do
  devise_for :users

  root "pages#home"

  # Public content
  resources :posts do
    resources :comments, only: [:create]
  end
  resources :categories
  resources :tags,       only: [:index, :show]
  resources :media,      only: [:index, :show, :new, :create, :destroy]

  # Moderator actions
  resources :comments, only: [:destroy] do
    member { post :moderate }
  end

  # Admin dashboard (any authenticated user, but shows editor/admin views)
  get "dashboard", to: "dashboard#show"

  # JSON API — mirrors the same endpoints for headless usage
  namespace :api do
    namespace :v1 do
      resources :posts, only: [:index, :show]
      resources :categories, only: [:index, :show]
      resources :tags, only: [:index, :show]
    end
  end

  # Health check for Render
  get "up" => "rails/health#show", as: :rails_health_check
end
