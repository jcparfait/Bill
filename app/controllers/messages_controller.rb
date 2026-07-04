class MessagesController < ApplicationController
  QUESTION_FLOW = [
    "Ask whether the user wants something calming, energizing, or quietly suitable for the evening.",
    "Ask whether the user wants something fresh, bitter, sweet, dry, fruity, strong, light, or comforting.",
    "Ask whether the drink should be alcoholic, light, alcohol-free, or include/exclude specific ingredients."
  ].freeze

  BILL_VOICE_PROMPT = <<~PROMPT
    You are Bill, a fictional cocktail bar host.
    Voice: calm, dry, understated, gently ironic, cinematic, never loud.
    You are not motivational, corporate, or theatrical.
    Reply in French.
    Keep it to 2 or 3 short sentences.
    Never list ingredients or recipes.
    Do not use emoji.
  PROMPT

  LIQUOR_INGREDIENTS = %w[gin vodka rum tequila whiskey bourbon brandy cognac campari vermouth champagne prosecco].freeze

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

    if closing_intent?
      close_conversation
    elsif should_recommend_cocktail?
      recommend_cocktail
    else
      ask_next_question
    end

    @chat.reload
    @chat.generate_title_from_first_exchange

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end

  private

  def closing_intent?
    return false if latest_user_text.blank?
    return false if wants_another_recommendation?
    return false if latest_message_has_new_constraints?

    latest_user_text.match?(closures_pattern)
  end

  def closures_pattern
    /\A(?:ok|merci|merci beaucoup|parfait|super|top|nickel|tres bien|ca me va|c est bon|c'est bon|ca ira|je prends|je vais prendre|bonne idee|allons y|vas y|go)(?:[\s.!?]+.*)?\z/
  end

  def wants_another_recommendation?
    latest_user_text.match?(/autre|un autre|autre chose|pas celui|pas ca|pas ça|change|nouveau|nouvelle proposition|repropose/)
  end

  def latest_message_has_new_constraints?
    latest_user_text.match?(/avec|sans|pas de|frais|amer|doux|sec|fruite|fort|leger|reconfort|petillant|cremeux|alcool|gin|vodka|rhum|rum|tequila|whisky|whiskey|menthe|citron|cafe|orange/)
  end

  def close_conversation
    @assistant_message.update!(content: closing_text)
    replace_assistant_message
  end

  def closing_text
    return fallback_closing_text unless llm_available?

    response = RubyLLM.chat
                      .with_instructions(BILL_VOICE_PROMPT)
                      .ask(closing_prompt)

    response.content.to_s.strip.presence || fallback_closing_text
  rescue StandardError => e
    Rails.logger.warn "Bill closing fallback: #{e.class} - #{e.message}"
    fallback_closing_text
  end

  def closing_prompt
    <<~PROMPT
      Recent user messages:
      #{recent_user_context}

      The user is accepting, thanking, or closing the conversation.
      Reply as Bill.
      Do not recommend another drink.
      Do not ask another question.
      Keep it short and natural.
    PROMPT
  end

  def fallback_closing_text
    "Parfait. Je te laisse avec ça, alors. Certaines soirées gagnent à ne pas être trop commentées."
  end

  def should_recommend_cocktail?
    return false if closing_intent?
    return false if user_messages_count < 4

    recommendation_ready? || user_explicitly_asks_for_cocktail? || user_messages_count >= 6
  end

  def recommendation_ready?
    conversation_signal_score >= 2
  end

  def conversation_signal_score
    score = 0
    score += 1 if normalized_text.match?(/fatigue|epuise|stress|anxieux|nerveux|fete|celebr|triste|melancol|chaud|calme|bof|forme|energie/)
    score += 1 if normalized_text.match?(/frais|amer|doux|sec|fruite|fort|leger|reconfort|petillant|cremeux|tropical/)
    score += 1 if wants_no_alcohol? || ingredient_constraints.values.any?(&:present?)
    score
  end

  def user_messages_count
    @chat.messages.where(role: "user").count
  end

  def user_explicitly_asks_for_cocktail?
    latest_user_text.match?(/propose|recommande|conseille|sers|donne|choisis|cocktail|boisson|verre|un autre|autre chose/)
  end

  def ask_next_question
    question = natural_question_text
    @assistant_message.update!(content: question)
    replace_assistant_message
  end

  def natural_question_text
    target = question_target
    return fallback_question(target) unless llm_available?

    response = RubyLLM.chat
                      .with_instructions(BILL_VOICE_PROMPT)
                      .ask(question_prompt(target))

    response.content.to_s.strip.presence || fallback_question(target)
  rescue StandardError => e
    Rails.logger.warn "Bill voice fallback: #{e.class} - #{e.message}"
    fallback_question(target)
  end

  def question_target
    QUESTION_FLOW[user_messages_count - 1] ||
      "Ask one missing detail that would help choose the drink without sounding like a form."
  end

  def fallback_question(target)
    case target
    when QUESTION_FLOW[0]
      "D'accord. Avant de sortir le shaker, tu veux quelque chose qui apaise, qui réveille, ou qui accompagne tranquillement la soirée ?"
    when QUESTION_FLOW[1]
      "Très bien. Tu penches plutôt vers frais, amer, doux, sec, fruité ou fort ?"
    when QUESTION_FLOW[2]
      "Dernier détail utile: alcoolisé, léger, sans alcool, ou avec un ingrédient précis à inclure ou à éviter ?"
    else
      "Il me manque encore un angle. Tu veux éviter quelque chose, ou tu me laisses choisir sans trop de cérémonie ?"
    end
  end

  def question_prompt(target)
    <<~PROMPT
      Recent user messages:
      #{recent_user_context}

      Current goal:
      #{target}

      Write Bill's next reply.
      It must end with exactly one short question.
      Do not recommend a drink yet.
      Do not mention cocktail names.
    PROMPT
  end

  def recommend_cocktail
    cocktail = fetch_cocktail_from_api

    if cocktail.present?
      @assistant_message.update!(content: recommendation_text(cocktail), cocktail: cocktail)
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

  def fetch_cocktail_from_api
    mood = cocktail_mood
    tool = RecommendCocktailTool.new(user: current_user, chat: @chat)

    cocktail_candidates.each do |candidate|
      result = tool.execute(cocktail_name: candidate[:name], mood: mood)
      Rails.logger.info "Bill cocktail result: #{result.inspect}"
      @chat.reload

      next if @chat.cocktail.blank?
      next if proposed_names_in_chat.include?(@chat.cocktail.name.downcase)

      return @chat.cocktail
    end

    nil
  end

  def cocktail_candidates
    constraints = ingredient_constraints
    excluded_names = proposed_names_in_chat
    selected_tags = mood_tags

    candidates = COCKTAIL_CATALOG.reject do |candidate|
      excluded_names.include?(candidate[:name].downcase) ||
        constraints[:excluded].intersect?(candidate[:ingredients]) ||
        constraints[:included].any? { |ingredient| candidate[:ingredients].exclude?(ingredient) }
    end

    candidates = candidates.select { |candidate| candidate[:tags].include?("mocktail") } if wants_no_alcohol?

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
    elsif normalized_text.match?(/fatigue|epuise|vide|longue journee|creve/)
      "fatigue, besoin de quelque chose de net mais pas brutal"
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

  def mood_tags
    text = normalized_text
    return %w[mocktail soft fresh] if wants_no_alcohol?
    return %w[fresh light] if text.match?(/chaud|soleil|ete|frais|rafraich|leger/)
    return %w[bitter dry slow] if text.match?(/amer|sec|calme|lent|digestion/)
    return %w[sweet creamy comfort soft] if text.match?(/doux|sucre|reconfort|triste|melancol|fatigue/)
    return %w[strong dry slow] if text.match?(/fort|cors|whisky|serieux/)
    return %w[fruity tropical fresh] if text.match?(/fruit|exotique|tropical|fete/)

    %w[fresh balanced soft]
  end

  def ingredient_constraints
    included = []
    excluded = []

    INGREDIENT_ALIASES.each do |ingredient, aliases|
      aliases.each do |name|
        excluded << ingredient if normalized_text.match?(/(sans|pas de|sans aucun|no|without)[^.!?,;]*(#{Regexp.escape(name)})/)
        included << ingredient if normalized_text.match?(/(avec|au|a la|a l|with|du|de la)[^.!?,;]*(#{Regexp.escape(name)})/)
      end
    end

    excluded.concat(LIQUOR_INGREDIENTS) if wants_no_alcohol?

    { included: included.uniq - excluded, excluded: excluded.uniq }
  end

  def wants_no_alcohol?
    normalized_text.match?(/sans alcool|non alcool|mocktail|virgin|soft|pas d alcool|pas de alcool/)
  end

  def proposed_names_in_chat
    @chat.messages
         .includes(:cocktail)
         .where.not(cocktail_id: nil)
         .map { |message| message.cocktail&.name.to_s.downcase }
         .compact
  end

  def recommendation_text(cocktail)
    return fallback_recommendation_text(cocktail) unless llm_available?

    response = RubyLLM.chat
                      .with_instructions(BILL_VOICE_PROMPT)
                      .ask(recommendation_prompt(cocktail))

    response.content.to_s.strip.presence || fallback_recommendation_text(cocktail)
  rescue StandardError => e
    Rails.logger.warn "Bill recommendation fallback: #{e.class} - #{e.message}"
    fallback_recommendation_text(cocktail)
  end

  def recommendation_prompt(cocktail)
    <<~PROMPT
      Recent user messages:
      #{recent_user_context}

      Mood detected by the app:
      #{cocktail_mood}

      Recommended cocktail:
      #{cocktail.name}

      Write Bill's recommendation.
      Start with: "Je te propose un #{cocktail.name}." or "Je partirais sur un #{cocktail.name}."
      Explain why it fits in one short sentence.
      Do not mention ingredients or recipe.
      Do not ask another question.
    PROMPT
  end

  def fallback_recommendation_text(cocktail)
    "Je te propose un #{cocktail.name}. #{recommendation_reason} La fiche est là, sobrement posée; ce qui est souvent mieux qu'un long discours au comptoir."
  end

  def recommendation_reason
    mood = cocktail_mood

    if wants_no_alcohol?
      "Ça reste dans une zone sans alcool, plus élégante que punitive."
    elsif mood.include?("fatigue")
      "Ça répond à cette fatigue sans transformer la soirée en bras de fer."
    elsif mood.include?("tendu")
      "C'est assez net pour marquer une pause, assez léger pour ne pas rajouter du bruit au bruit."
    elsif mood.include?("festif")
      "Ça garde de l'élan, avec juste assez de tenue pour ne pas partir dans tous les sens."
    elsif mood.include?("melancolique")
      "C'est doux sans être mou, ce qui est une petite victoire discrète."
    else
      "C'est équilibré, précis, et ça laisse la soirée décider du reste."
    end
  end

  def recent_user_context
    @chat.messages
         .where(role: "user")
         .order(created_at: :desc)
         .limit(4)
         .reverse
         .pluck(:content)
         .join("\n")
  end

  def latest_user_text
    @latest_user_text ||= I18n.transliterate(@message.content.to_s.downcase.squish)
  end

  def llm_available?
    ENV["GITHUB_TOKEN"].present? || ENV["OPENAI_API_KEY"].present?
  end

  def normalized_text
    @normalized_text ||= I18n.transliterate(
      @chat.messages.where(role: "user").order(:created_at, :id).pluck(:content).join(" ").downcase
    )
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
