Rails.application.routes.draw do
  devise_for :users

  root to: "pages#home"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :cocktails

  resources :chats, only: [:index, :show, :create, :destroy] do
    resources :messages, only: [:create]
  end
end
