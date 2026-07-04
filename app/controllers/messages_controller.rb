class MessagesController < ApplicationController
  BILL_DECISION_PROMPT = <<~PROMPT
    You are Bill, a fictional cocktail bar host.
    Voice: calm, dry, understated, gently ironic, cinematic, never loud.
    You are not motivational, corporate, or theatrical.
    Reply in French.

    Your job is to have a real bar conversation first, then recommend a cocktail only when it makes sense.
    Understand the user's latest message literally: greetings, names, thanks, acceptance, refusal, hesitation, jokes, and ingredient constraints all matter.
    Do not repeat bonsoir/bonjour if Bill has already greeted in the conversation.
    If the user gives their name, acknowledge it briefly and continue naturally.
    If the user thanks you, accepts, says it is fine, or closes the conversation, answer naturally and do not recommend another cocktail.
    If the user dislikes a cocktail or asks for another one, continue toward a new recommendation.
    Ask at most one question at a time.

    Prefer action "chat" until you have enough useful information about mood and drink preference.
    Choose action "recommend" only when the user has given enough signal to pick a cocktail, or explicitly asks you to choose/recommend/serve one.
    Before recommending, try to know at least: mood or occasion, taste direction, and alcohol/ingredient constraints.

    Return strict JSON only, with this shape:
    {
      "action": "chat" or "recommend",
      "content": "Bill's natural reply when action is chat. Empty string when action is recommend.",
      "mood": "short mood summary in French",
      "tags": ["fresh", "dry", "sweet", "bitter", "fruity", "strong", "light", "comfort", "sparkling", "creamy", "tropical", "mocktail", "soft"],
      "include": ["gin", "vodka", "rum", "tequila", "whiskey", "brandy", "campari", "vermouth", "champagne", "prosecco", "coffee", "mint", "lime", "lemon", "orange", "cranberry", "ginger", "cream", "coconut", "pineapple"],
      "exclude": ["gin", "vodka", "rum", "tequila", "whiskey", "brandy", "campari", "vermouth", "champagne", "prosecco", "coffee", "mint", "lime", "lemon", "orange", "cranberry", "ginger", "cream", "coconut", "pineapple"],
      "no_alcohol": true or false
    }

    Keep chat content to 1 or 2 short sentences.
    Never list ingredients or recipes.
    Do not use emoji.
  PROMPT

  BILL_RECOMMENDATION_PROMPT = <<~PROMPT
    You are Bill, a fictional cocktail bar host.
    Voice: calm, dry, understated, gently ironic, cinematic, never loud.
    Reply in French.
    Keep it to 2 short sentences.
    Do not list ingredients or recipes.
    Do not use emoji.
  PROMPT

  LIQUOR_INGREDIENTS = %w[gin vodka rum tequila whiskey bourbon brandy cognac campari vermouth champagne prosecco].freeze

  ALLOWED_TAGS = %w[
    fresh dry sweet bitter fruity strong light comfort sparkling creamy tropical mocktail soft sour simple
    aromatic elegant aperitif slow citrus lively honey floral spicy easy balanced
  ].freeze

  INGREDIENT_ALIASES = {
    "gin" => ["gin"],
    "vodka" => ["vodka"],
    "rum" => ["rum", "rhum"],
    "tequila" => ["tequila"],
    "whiskey" => ["whiskey", "whisky"],
    "bourbon" => ["bourbon"],
    "brandy" => ["brandy", "cognac"],
    "campari" => ["campari"],
    "vermouth" => ["vermouth"],
    "champagne" => ["champagne"],
    "prosecco" => ["prosecco"],
    "coffee" => ["coffee", "cafe", "espresso"],
    "mint" => ["mint", "menthe"],
    "lime" => ["lime", "citron vert"],
    "lemon" => ["lemon", "citron"],
    "orange" => ["orange"],
    "cranberry" => ["cranberry", "canneberge"],
    "ginger" => ["ginger", "gingembre"],
    "cream" => ["cream", "creme"],
    "coconut" => ["coconut", "coco"],
    "pineapple" => ["pineapple", "ananas"]
  }.freeze

  COCKTAIL_CATALOG = [
    { name: "Daiquiri", tags: %w[fresh dry sour simple], ingredients: %w[rum lime] },
    { name: "Gimlet", tags: %w[fresh dry simple], ingredients: %w[gin lime] },
    { name: "Southside", tags: %w[fresh light aromatic], ingredients: %w[gin mint lemon] },
    { name: "Tom Collins", tags: %w[fresh light sparkling], ingredients: %w[gin lemon] },
    { name: "French 75", tags: %w[fresh sparkling elegant], ingredients: %w[gin lemon champagne] },
    { name: "Paloma", tags: %w[fresh fruity light], ingredients: %w[tequila] },
    { name: "Moscow Mule", tags: %w[fresh spicy easy], ingredients: %w[vodka ginger lime] },
    { name: "Americano", tags: %w[light bitter aperitif], ingredients: %w[campari vermouth] },
    { name: "Boulevardier", tags: %w[bitter strong slow], ingredients: %w[whiskey campari vermouth] },
    { name: "Sidecar", tags: %w[dry citrus elegant], ingredients: %w[brandy lemon] },
    { name: "Bramble", tags: %w[fruity fresh soft], ingredients: %w[gin lemon] },
    { name: "Caipirinha", tags: %w[fresh lively simple], ingredients: %w[lime] },
    { name: "Bee's Knees", tags: %w[soft fresh honey], ingredients: %w[gin lemon] },
    { name: "Whiskey Sour", tags: %w[comfort sour balanced], ingredients: %w[whiskey lemon] },
    { name: "Pisco Sour", tags: %w[soft sour elegant], ingredients: %w[lemon] },
    { name: "Clover Club", tags: %w[soft fruity elegant], ingredients: %w[gin lemon] },
    { name: "Aviation", tags: %w[floral dry elegant], ingredients: %w[gin lemon] },
    { name: "Sea Breeze", tags: %w[fruity light fresh], ingredients: %w[vodka cranberry] },
    { name: "Mai Tai", tags: %w[tropical strong fruity], ingredients: %w[rum lime] },
    { name: "Planter's Punch", tags: %w[tropical fruity comfort], ingredients: %w[rum] },
    { name: "Sazerac", tags: %w[strong dry slow], ingredients: %w[whiskey] },
    { name: "Rusty Nail", tags: %w[strong slow comfort], ingredients: %w[whiskey] },
    { name: "White Russian", tags: %w[sweet creamy comfort], ingredients: %w[vodka coffee cream] },
    { name: "Grasshopper", tags: %w[sweet creamy soft], ingredients: %w[cream mint] },
    { name: "Afterglow", tags: %w[soft fruity mocktail], ingredients: %w[orange pineapple] },
    { name: "Fruit Cooler", tags: %w[soft fresh mocktail], ingredients: %w[orange lemon] },
    { name: "Shirley Temple", tags: %w[soft sweet mocktail], ingredients: %w[ginger] }
  ].freeze

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    unless @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_message_container",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          )
        end
        format.html { render "chats/show", status: :unprocessable_entity }
      end
      return
    end

    broadcast_message(@message)

    @assistant_message = Message.create!(role: "bartender", content: "", chat: @chat)
    broadcast_message(@assistant_message)

    decision = conversation_decision

    if decision[:action] == "recommend" && recommendation_allowed?
      recommend_cocktail(decision)
    else
      continue_conversation(decision)
    end

    @chat.reload
    @chat.generate_title_from_first_exchange

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end

  private

  def conversation_decision
    return fallback_decision unless llm_available?

    response = RubyLLM.chat
                      .with_instructions(BILL_DECISION_PROMPT)
                      .ask(decision_prompt)

    parse_decision(response.content)
  rescue StandardError => e
    Rails.logger.warn "Bill decision fallback: #{e.class} - #{e.message}"
    fallback_decision
  end

  def decision_prompt
    <<~PROMPT
      Conversation so far:
      #{conversation_context}

      Latest user message:
      #{latest_user_message}

      User messages count in this chat: #{user_messages_count}
      Already proposed cocktails: #{proposed_names_in_chat.join(", ").presence || "none"}

      Decide Bill's next move.
      If the user is simply answering a normal question, respond to that answer and continue naturally.
      If the user says their name, do not ignore it.
      If Bill has already greeted, do not greet again.
      If the user is done, grateful, or accepting the suggestion, choose action "chat".
      If action is "recommend", the app will fetch the cocktail from an API, so do not write a recommendation in content.
    PROMPT
  end

  def parse_decision(raw_content)
    raw_json = raw_content.to_s.strip[/\{.*\}/m] || raw_content.to_s
    data = JSON.parse(raw_json)

    {
      action: data["action"] == "recommend" ? "recommend" : "chat",
      content: data["content"].to_s.strip,
      mood: data["mood"].to_s.strip,
      tags: normalize_tags(data["tags"]),
      include: normalize_ingredients(data["include"]),
      exclude: normalize_ingredients(data["exclude"]),
      no_alcohol: data["no_alcohol"] == true
    }
  rescue JSON::ParserError => e
    Rails.logger.warn "Bill decision JSON fallback: #{e.class} - #{e.message}"
    fallback_decision
  end

  def normalize_tags(value)
    Array(value).map { |tag| normalize_text(tag) }.select { |tag| ALLOWED_TAGS.include?(tag) }.uniq
  end

  def normalize_ingredients(value)
    Array(value).map { |ingredient| normalize_text(ingredient) }.select { |ingredient| INGREDIENT_ALIASES.key?(ingredient) }.uniq
  end

  def continue_conversation(decision)
    content = decision[:content].presence || fallback_chat_text
    @assistant_message.update!(content: content)
    replace_assistant_message
  end

  def fallback_decision
    {
      action: user_messages_count >= 4 || user_explicitly_asks_for_cocktail? ? "recommend" : "chat",
      content: fallback_chat_text,
      mood: cocktail_mood,
      tags: mood_tags,
      include: [],
      exclude: [],
      no_alcohol: wants_no_alcohol?
    }
  end

  def fallback_chat_text
    if user_messages_count <= 1
      "D'accord. On va faire ça proprement, ce qui est déjà une ambition raisonnable. Tu veux quelque chose de plutôt calme, frais, fort, ou doux ?"
    elsif user_messages_count == 2
      "Je vois le genre. Et côté verre, tu veux rester léger, partir sur quelque chose d'alcoolisé, ou éviter un ingrédient précis ?"
    else
      "On approche du comptoir. Donne-moi juste une dernière direction: frais, amer, fruité, sec, ou réconfortant ?"
    end
  end

  def recommendation_allowed?
    user_messages_count >= 3 || user_explicitly_asks_for_cocktail?
  end

  def user_messages_count
    @chat.messages.where(role: "user").count
  end

  def user_explicitly_asks_for_cocktail?
    latest_user_text.match?(/propose|recommande|conseille|sers|donne|choisis|cocktail|boisson|verre|un autre|autre chose/)
  end

  def recommend_cocktail(decision = {})
    cocktail = fetch_cocktail_from_api(decision)

    if cocktail.present?
      @assistant_message.update!(content: recommendation_text(cocktail, decision), cocktail: cocktail)
      replace_assistant_message
      broadcast_cocktail_card(cocktail)
      broadcast_glass_animation
    else
      @assistant_message.update!(
        content: "Je n'ai pas trouvé de cocktail fiable avec ces contraintes. Même les bars feutrés ont leurs limites, généralement rangées derrière les bouteilles vides."
      )
      replace_assistant_message
    end
  end

  def fetch_cocktail_from_api(decision = {})
    mood = decision[:mood].presence || cocktail_mood
    tool = RecommendCocktailTool.new(user: current_user, chat: @chat)

    cocktail_candidates(decision).each do |candidate|
      result = tool.execute(cocktail_name: candidate[:name], mood: mood)
      Rails.logger.info "Bill cocktail result: #{result.inspect}"
      @chat.reload

      next if @chat.cocktail.blank?
      next if proposed_names_in_chat.include?(@chat.cocktail.name.downcase)

      return @chat.cocktail
    end

    nil
  end

  def cocktail_candidates(decision = {})
    constraints = ingredient_constraints(decision)
    excluded_names = proposed_names_in_chat
    selected_tags = mood_tags(decision)

    candidates = COCKTAIL_CATALOG.reject do |candidate|
      excluded_names.include?(candidate[:name].downcase) ||
        constraints[:excluded].intersect?(candidate[:ingredients]) ||
        constraints[:included].any? { |ingredient| candidate[:ingredients].exclude?(ingredient) }
    end

    candidates = candidates.select { |candidate| candidate[:tags].include?("mocktail") } if wants_no_alcohol?(decision)

    candidates.sort_by do |candidate|
      [
        -(candidate[:tags] & selected_tags).size,
        candidate[:tags].include?("mocktail") ? 0 : 1,
        candidate[:name]
      ]
    end.first(8)
  end

  def cocktail_mood
    if wants_no_alcohol?
      "sans alcool, doux et prudent"
    elsif normalized_text.match?(/fatigue|epuise|vide|longue journee|creve|detendre|relax|relacher/)
      "fatigue ou tension, besoin de quelque chose de net mais pas brutal"
    elsif normalized_text.match?(/stress|anxieux|nerveux|pression|tendu/)
      "tendu, besoin de calme et de legerete"
    elsif normalized_text.match?(/fete|celebr|danser|sortie|amis/)
      "festif, envie de quelque chose de vivant"
    elsif normalized_text.match?(/triste|melancol|seul|solitude|bof/)
      "melancolique, besoin de douceur"
    elsif normalized_text.match?(/chaud|soleil|ete|frais|rafraich/)
      "envie de fraicheur"
    else
      "humeur calme, envie d'un cocktail equilibre"
    end
  end

  def mood_tags(decision = {})
    decision_tags = Array(decision[:tags]).presence
    return decision_tags if decision_tags.present?

    text = normalized_text
    return %w[mocktail soft fresh] if wants_no_alcohol?(decision)
    return %w[fresh light] if text.match?(/chaud|soleil|ete|frais|rafraich|leger|detendre|relax/)
    return %w[bitter dry slow] if text.match?(/amer|sec|calme|lent|digestion/)
    return %w[sweet creamy comfort soft] if text.match?(/doux|sucre|reconfort|triste|melancol|fatigue/)
    return %w[strong dry slow] if text.match?(/fort|cors|whisky|serieux/)
    return %w[fruity tropical fresh] if text.match?(/fruit|exotique|tropical|fete/)

    %w[fresh balanced soft]
  end

  def ingredient_constraints(decision = {})
    included = Array(decision[:include])
    excluded = Array(decision[:exclude])

    INGREDIENT_ALIASES.each do |ingredient, aliases|
      aliases.each do |name|
        excluded << ingredient if normalized_text.match?(/(sans|pas de|sans aucun|no|without)[^.!?,;]*(#{Regexp.escape(name)})/)
        included << ingredient if normalized_text.match?(/(avec|au|a la|a l|with|du|de la)[^.!?,;]*(#{Regexp.escape(name)})/)
      end
    end

    excluded.concat(LIQUOR_INGREDIENTS) if wants_no_alcohol?(decision)

    { included: included.uniq - excluded, excluded: excluded.uniq }
  end

  def wants_no_alcohol?(decision = {})
    decision[:no_alcohol] == true || normalized_text.match?(/sans alcool|non alcool|mocktail|virgin|soft|pas d alcool|pas de alcool/)
  end

  def proposed_names_in_chat
    @chat.messages
         .includes(:cocktail)
         .where.not(cocktail_id: nil)
         .map { |message| message.cocktail&.name.to_s.downcase }
         .compact
  end

  def recommendation_text(cocktail, decision = {})
    return fallback_recommendation_text(cocktail, decision) unless llm_available?

    response = RubyLLM.chat
                      .with_instructions(BILL_RECOMMENDATION_PROMPT)
                      .ask(recommendation_prompt(cocktail, decision))

    response.content.to_s.strip.presence || fallback_recommendation_text(cocktail, decision)
  rescue StandardError => e
    Rails.logger.warn "Bill recommendation fallback: #{e.class} - #{e.message}"
    fallback_recommendation_text(cocktail, decision)
  end

  def recommendation_prompt(cocktail, decision = {})
    <<~PROMPT
      Conversation so far:
      #{conversation_context}

      Mood understood by Bill:
      #{decision[:mood].presence || cocktail_mood}

      Cocktail returned by the API:
      #{cocktail.name}

      Write Bill's recommendation.
      Start naturally with the cocktail name, for example "Je partirais sur un #{cocktail.name}."
      Explain why it fits the user's mood in one short sentence.
      Do not ask another question.
    PROMPT
  end

  def fallback_recommendation_text(cocktail, decision = {})
    "Je partirais sur un #{cocktail.name}. #{recommendation_reason(decision)}"
  end

  def recommendation_reason(decision = {})
    mood = decision[:mood].presence || cocktail_mood

    if wants_no_alcohol?(decision)
      "Ça reste sans alcool, mais pas sans intention; c'est déjà mieux que beaucoup de réunions."
    elsif mood.include?("fatigue") || mood.include?("tension")
      "Ça devrait détendre l'affaire sans transformer la soirée en négociation internationale."
    elsif mood.include?("festif")
      "Ça garde de l'élan, avec juste assez de tenue pour ne pas partir dans tous les sens."
    elsif mood.include?("melancolique")
      "C'est doux sans être mou, ce qui est une petite victoire discrète."
    else
      "C'est équilibré, précis, et ça laisse la soirée décider du reste."
    end
  end

  def conversation_context
    @chat.messages
         .order(:created_at, :id)
         .last(10)
         .filter_map do |message|
           next if message.content.blank?

           speaker = message.role == "user" ? "User" : "Bill"
           "#{speaker}: #{message.content}"
         end
         .join("\n")
  end

  def latest_user_message
    @message.content.to_s.strip
  end

  def latest_user_text
    @latest_user_text ||= normalize_text(latest_user_message)
  end

  def llm_available?
    ENV["GITHUB_TOKEN"].present? || ENV["OPENAI_API_KEY"].present?
  end

  def normalized_text
    @normalized_text ||= normalize_text(
      @chat.messages.where(role: "user").order(:created_at, :id).pluck(:content).join(" ")
    )
  end

  def normalize_text(value)
    I18n.transliterate(value.to_s.downcase.squish)
  end

  def broadcast_message(message)
    Turbo::StreamsChannel.broadcast_before_to(
      @chat,
      target: "messages-bottom",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def replace_assistant_message
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: helpers.dom_id(@assistant_message),
      partial: "messages/message",
      locals: { message: @assistant_message }
    )
  end

  def broadcast_cocktail_card(cocktail)
    Turbo::StreamsChannel.broadcast_update_to(
      @chat,
      target: "cocktail-card-container",
      partial: "chats/cocktail_recommendation",
      locals: { cocktail: cocktail, chat: @chat }
    )
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def broadcast_glass_animation
    Turbo::StreamsChannel.broadcast_update_to(
      @chat,
      target: "glass-animation-container",
      html: '<div class="sliding-glass"></div>'
    )
  end
end
