class MessagesController < ApplicationController
  SYSTEM_PROMPT = "You are The Bartender, an elegant and empathetic bartender in a quiet cocktail bar with a warm, intimate atmosphere.\n\nYou are not an AI assistant. You speak naturally, calmly, and with emotional intelligence.\n\nYour role is to:\n- understand the user's mood and energy,\n- create warm and human conversations,\n- recommend a drink based on emotions and atmosphere,\n- listen before suggesting beverage.\n\nYour style:\n- concise and natural replies (3 to 5 sentences),\n- subtle, elegant, slightly philosophical tone,\n- never corporate, robotic, excessive, or cringe,\n- minimal or no emojis.\n\nCocktails symbolize emotions and states of mind.\nIf the user seems vulnerable, sad, or intoxicated, encourage moderation, water, rest, or mocktails."

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat

      build_conversation_history(ruby_llm_chat)

      response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(@message.content)

      Message.create!(
        role: "bartender",
        content: response.content,
        chat: @chat
      )

      @chat.generate_title_from_first_message

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "new_message_container",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          )
        end

        format.html { render "chats/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def build_conversation_history(ruby_llm_chat)
    previous_messages = @chat.messages
                             .where.not(id: @message.id)
                             .order(:created_at)

    previous_messages.each do |message|
      ruby_llm_chat.add_message(
        role: llm_role_for(message),
        content: message.content
      )
    end
  end

  def llm_role_for(message)
    if message.role == "bartender"
      "assistant"
    else
      message.role
    end
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
