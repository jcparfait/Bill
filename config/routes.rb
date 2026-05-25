Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  get "up" => "rails/health#show", as: :rails_health_check

  ressources :cocktails
  ressources :chats, only:[:index, :show, :create, :delete] do
    ressources :messages, only:[:create]
  end

end
