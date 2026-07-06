Rails.application.routes.draw do
  devise_for :users

  root to: "chats#new"

  get "up" => "rails/health#show", as: :rails_health_check

  resource :profile, only: :show

  resources :cocktails

  resources :chats, only: [:index, :new, :show, :create, :destroy] do
    resources :messages, only: [:create]
    member do
      patch :save_cocktail
      patch :remove_cocktail
    end
  end
end
