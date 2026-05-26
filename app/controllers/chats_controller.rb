class ChatsController < ApplicationController
  before_action :set_chat, only: %i[show destroy]

  def index
    @chats = current_user.chats.order(created_at: :desc)
  end

  def new
    @chat = Chat.new
  end

  def create
    @chat = current_user.chats.new(title: "Untitled conversation")

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

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
