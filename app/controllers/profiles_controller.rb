class ProfilesController < ApplicationController
  def show
    @chats = current_user.chats.includes(:cocktail).order(created_at: :desc)
  end
end
