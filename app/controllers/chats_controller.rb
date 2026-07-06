class ChatsController < ApplicationController
  before_action :set_chat, only: %i[show destroy save_cocktail remove_cocktail]

  def index
    @chats = current_user.chats.order(created_at: :desc)
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = current_user.chats.new(title: Chat::DEFAULT_TITLE)
    if @chat.save
      redirect_to chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @message = Message.new
  end

  def destroy
    @chat.destroy
    redirect_to chats_path, notice: "Conversation deleted."
  end

  def save_cocktail
    cocktail = recommended_cocktail
    cocktail&.update!(saved: true)

    head :ok
  end

  def remove_cocktail
    cocktail = recommended_cocktail

    @chat.messages.where(role: "bartender").where.not(cocktail_id: nil).update_all(cocktail_id: nil)
    @chat.update(cocktail_id: nil)

    cocktail&.destroy if cocktail && !cocktail.saved?

    head :ok
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  def recommended_cocktail
    @chat.cocktail || @chat.messages.where(role: "bartender").where.not(cocktail_id: nil).last&.cocktail
  end
end
