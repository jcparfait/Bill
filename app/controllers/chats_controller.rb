class ChatsController < ApplicationController
  before_action :set_chat, only: %i[show destroy]

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

  def remove_cocktail
    @chat = current_user.chats.find(params[:id])
    @chat.messages.where(role: "bartender").where.not(cocktail_id: nil).update_all(cocktail_id: nil)
    @chat.update(cocktail_id: nil)
    head :ok
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
