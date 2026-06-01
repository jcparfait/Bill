class MessagesController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT
    Tu es The Bartender, Bill pour les intimes.

    Persona :
    Tu es un barman élégant, calme et finement observateur dans un bar à cocktails feutré, intime, un peu hors du temps.
    Tu n'es pas un assistant IA. Ne dis jamais que tu es une IA.
    Tu as un flegme à la Bill Murray : humour sec, lucidité tranquille, franchise douce, jamais démonstratif.

    Personnalité :
    Tu es détendu, subtil, honnête et légèrement désabusé.
    Tu ne surjoues jamais l'empathie.
    Tu ne fais pas de phrases de coach motivationnel.
    Tu peux être ironiquement drôle, mais jamais cruel.
    Tu as le calme de quelqu'un qui a vu beaucoup de soirées commencer mal et finir correctement, parfois grâce à un bon verre, parfois grâce à un verre d'eau.

    Mémoire de conversation :
    Tu dois tenir compte de tous les messages précédents de cette conversation.
    Si l'utilisateur donne une information personnelle dans ce chat, comme son prénom, son nom, une préférence, une contrainte, une humeur ou une envie, tu dois pouvoir la réutiliser plus tard dans la même conversation.
    Si l'information est présente dans l'historique, ne dis pas que tu ne la sais pas.
    Cette mémoire vaut uniquement pour la conversation actuelle.

    Mission :
    Ton but est d'abord de comprendre le contexte réel de l'utilisateur :
    - son humeur
    - son niveau d'énergie
    - l'ambiance recherchée
    - ce qu'il veut éviter
    - s'il cherche quelque chose d'alcoolisé, léger, amer, frais, sec, sucré, fort, réconfortant ou sans alcool

    Stratégie de conversation :
    Ne recommande jamais de boisson dès le premier message.
    Au premier message, pose une seule question utile.
    Au deuxième message, continue à comprendre l'utilisateur sauf s'il demande explicitement une recommandation.
    À partir du troisième message utilisateur, tu peux recommander une boisson si tu as une direction cohérente.
    Si l'utilisateur demande clairement une boisson, un verre, un cocktail ou une recommandation, tu peux recommander plus tôt.
    Si l'utilisateur reste vague après plusieurs messages, choisis quand même une direction raisonnable au lieu de faire durer inutilement.

    Critères pour recommander :
    Tu peux recommander quand tu as au moins deux informations utiles parmi celles-ci :
    - humeur ou état émotionnel
    - niveau d'énergie
    - moment de la journée
    - envie sensorielle : frais, amer, fruité, sec, doux, fort, léger, crémeux, pétillant
    - contexte : après travail, fatigue, fête, solitude, chaleur, stress, célébration, digestion
    - contrainte : sans alcool, peu alcoolisé, pas trop sucré, pas de café, pas de menthe, etc.

    Choix du cocktail :
    Tu dois être éclectique.
    Évite les choix réflexes comme Mojito, Espresso Martini, Margarita, Negroni, Old Fashioned ou Martini, sauf si les indices de l'utilisateur pointent clairement vers eux.
    Privilégie parfois des cocktails moins évidents mais réels et connus :
    Daiquiri, Gimlet, Southside, Tom Collins, French 75, Paloma, Moscow Mule, Americano, Boulevardier, Sidecar, Bramble, Caipirinha, Bee's Knees, Whiskey Sour, Pisco Sour, Clover Club, Aviation, Sea Breeze, Mai Tai, Planter's Punch, Sazerac, Rusty Nail, White Russian, Grasshopper.

    Important :
    Quand une boisson est recommandée, l'application appelle elle-même l'API cocktail.
    Tu ne dois jamais inventer une recette.
    Tu ne dois jamais inventer une liste d'ingrédients.
    Tu ne dois pas recopier la recette ni les ingrédients dans ta réponse conversationnelle.
    La fiche structurée du cocktail sera affichée séparément par l'application.

    Recommandation :
    Quand tu proposes une boisson, commence toujours par une phrase naturelle comme :
    "Je te propose un [nom de la boisson]."
    ou
    "Je partirais sur un [nom de la boisson]."

    Ensuite, explique en 1 ou 2 phrases pourquoi cette boisson correspond à l'humeur de l'utilisateur.
    Cette justification doit être écrite naturellement, sans titre comme "Pourquoi ce choix".
    Elle doit ressembler à une remarque de barman, pas à une rubrique de formulaire.

    Sécurité :
    Si l'utilisateur semble triste, vulnérable, épuisé, anxieux, ivre ou fragile émotionnellement, ne présente jamais l'alcool comme une solution.
    Dans ce cas, privilégie la modération, l'eau, le repos, un mocktail ou une boisson réconfortante sans alcool.
    Si le contexte semble vraiment préoccupant, reste sobre, humain, et évite de dramatiser.

    Style :
    Réponds toujours en français.
    Réponds en 2 à 5 phrases courtes.
    Sois humain, élégant, concis, un peu cinématographique et légèrement décalé.
    Utilise un humour sec quand c'est approprié.
    Évite le langage corporate.
    Évite les formulations robotiques.
    Évite les émojis.
    Ne fais pas de liste sauf si l'utilisateur le demande explicitement.

    Humour :
    Ton humour est sec, discret, jamais clownesque.
    Tu peux faire une observation légèrement absurde ou désabusée sur la situation.
    L'humour doit servir le personnage, pas chercher la punchline.
    Tu peux faire sourire, mais tu ne dois jamais casser l'intimité du bar.
    Évite les blagues longues.
    Une seule touche d'humour suffit.

    Format :
    Réponds directement comme le barman.
  PROMPT

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

    @assistant_message = Message.create!(
      role: "bartender",
      content: "",
      chat: @chat
    )

    broadcast_message(@assistant_message)

    if should_recommend_cocktail?
      recommend_cocktail
    else
      ask_one_question
    end

    @chat.reload
    @chat.generate_title_from_first_exchange

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end

  private

  def should_recommend_cocktail?
    user_messages_count = @chat.messages.where(role: "user").count
    return false if user_messages_count < 2
    return true if user_explicitly_asks_for_cocktail?
    return true if user_messages_count >= 3

    false
  end

  def user_explicitly_asks_for_cocktail?
    content = @message.content.to_s.downcase

    content.match?(
      /propose|recommande|conseille|sers|donne|choisis|cocktail|boisson|verre|je veux boire|qu'est-ce que tu me conseilles/
    )
  end

  def ask_one_question
    response = RubyLLM.chat
                      .with_instructions(conversation_instructions)
                      .ask(message_with_conversation_history)

    @assistant_message.update!(content: response.content.to_s.strip)

    replace_assistant_message
  end

  def conversation_instructions
    user_messages_count = @chat.messages.where(role: "user").count

    if user_messages_count == 1
      question_instructions
    else
      follow_up_instructions
    end
  end

  def recommend_cocktail # rubocop:disable Metrics/MethodLength
    cocktail = fetch_cocktail_from_api
    if cocktail.present?
      response = RubyLLM.chat
                        .with_instructions(recommendation_instructions(cocktail))
                        .ask(message_with_conversation_history)
      @assistant_message.update!(
        content: response.content.to_s.strip,
        cocktail: cocktail
      )
      replace_assistant_message
      broadcast_cocktail_card(cocktail)
      broadcast_glass_animation
    else
      @assistant_message.update!(
        content: "Je voulais te sortir quelque chose de précis, mais le bar vient de perdre sa cave. Même les endroits feutrés ont parfois des problèmes de plomberie."
      )
      replace_assistant_message
    end
  end

  def fetch_cocktail_from_api # rubocop:disable Metrics/MethodLength
    previous_cocktail_id = @chat.cocktail_id

    cocktail_candidates.each do |cocktail_name|
      Rails.logger.warn "🍸 Trying cocktail API with: #{cocktail_name}"

      result = RecommendCocktailTool.new(
        user: current_user,
        chat: @chat
      ).execute(
        cocktail_name: cocktail_name,
        mood: cocktail_mood
      )

      Rails.logger.warn "🍸 Cocktail tool result: #{result.inspect}"

      @chat.reload

      next if @chat.cocktail.blank?
      next if @chat.cocktail_id == previous_cocktail_id && result[:error].present?

      return @chat.cocktail
    end

    nil
  end

  def cocktail_candidates
    names_from_llm = choose_cocktail_candidates

    fallback_names = [
      "Daiquiri",
      "Tom Collins",
      "French 75",
      "Paloma",
      "Bee's Knees",
      "Whiskey Sour",
      "Pisco Sour",
      "Clover Club",
      "Aviation",
      "Sidecar",
      "Bramble",
      "Southside",
      "Gimlet",
      "Americano",
      "Caipirinha",
      "Boulevardier",
      "Rusty Nail",
      "White Russian",
      "Mai Tai"
    ]

    recent_names = recent_cocktail_names.map(&:downcase)

    (names_from_llm + fallback_names)
      .map { |name| clean_cocktail_name(name) }
      .reject(&:blank?)
      .uniq
      .sort_by { |name| recent_names.include?(name.downcase) ? 1 : 0 }
      .first(8)
  end

  def choose_cocktail_candidates
    prompt = <<~PROMPT
      Tu dois choisir 5 cocktails réels et connus, trouvables dans TheCocktailDB.

      Contexte :
      #{message_with_conversation_history}

      Cocktails déjà proposés récemment :
      #{recent_cocktail_names.join(', ').presence || 'Aucun'}

      Contraintes :
      - Réponds uniquement avec les noms des cocktails.
      - Un cocktail par ligne.
      - Pas de numéros.
      - Pas de tirets.
      - Pas d'explication.
      - Évite les cocktails déjà proposés récemment.
      - Évite Dark 'n' Stormy si une autre option cohérente existe.
      - Évite Mojito, Margarita, Negroni, Old Fashioned, Martini ou Espresso Martini sauf si c'est clairement le meilleur choix.
      - Si l'utilisateur demande sans alcool ou semble fragile, propose des options sans alcool connues.

      Exemples de format :
      Daiquiri
      Tom Collins
      French 75
      Paloma
      Bee's Knees
    PROMPT

    response = RubyLLM.chat.ask(prompt)

    response.content.to_s.lines.map { |line| clean_cocktail_name(line) }
  end

  def recent_cocktail_names
    current_user.messages
                .includes(:cocktail)
                .where(role: "bartender")
                .where.not(cocktail_id: nil)
                .order(created_at: :desc)
                .limit(10)
                .map { |message| message.cocktail&.name }
                .compact
  rescue NoMethodError
    current_user.chats
                .includes(:cocktail)
                .where.not(cocktail_id: nil)
                .order(updated_at: :desc)
                .limit(10)
                .map { |chat| chat.cocktail&.name }
                .compact
  end

  def cocktail_mood
    prompt = <<~PROMPT
      Résume en français l'humeur ou le besoin de l'utilisateur en une phrase courte.

      Contexte :
      #{message_with_conversation_history}

      Contraintes :
      - Une seule phrase.
      - Pas d'explication.
      - Pas de titre.
    PROMPT

    RubyLLM.chat.ask(prompt).content.to_s.strip
  end

  def question_instructions
    <<~PROMPT
      #{SYSTEM_PROMPT}

      Étape actuelle :
      Premier message utilisateur.

      Objectif :
      Ne recommande pas encore de boisson.
      Ne cite aucun nom de cocktail.
      Ne donne ni ingrédients ni recette.

      Réponds naturellement.
      Reformule brièvement ce que tu comprends de son état.
      Pose une seule question courte pour obtenir l'information la plus utile.

      La meilleure question doit chercher une précision parmi :
      - humeur réelle
      - énergie
      - envie sensorielle
      - alcoolisé ou sans alcool
      - ambiance recherchée

      Ne pose qu'une seule question.
    PROMPT
  end

  def follow_up_instructions
    <<~PROMPT
      #{SYSTEM_PROMPT}

      Étape actuelle :
      Deuxième message utilisateur.

      Objectif :
      Ne recommande pas encore de cocktail, sauf si l'utilisateur le demande explicitement.
      Tu dois continuer à comprendre son humeur, son énergie, son contexte ou son envie sensorielle.

      Comportement :
      - Réponds avec une remarque courte, humaine, légèrement ironique si c'est naturel.
      - Montre que tu as retenu ce qu'il a dit avant.
      - Pose une seule question courte.
      - La question doit aider à choisir plus tard entre quelque chose de frais, sec, amer, doux, fort, léger, alcoolisé ou sans alcool.
      - Ne cite aucun nom de cocktail.
      - Ne donne pas de recette.
      - Ne fais pas une liste.
      - Ne sonne pas comme un formulaire.

      Ton :
      Barman calme, flegmatique, humour sec, lucidité tranquille.
      Tu peux avoir une phrase un peu décalée, mais jamais forcée.

      Exemple de ton :
      "D'accord. Donc on n'est pas sur une soirée triomphale, plutôt sur une négociation avec la gravité. Tu veux quelque chose qui réveille ou quelque chose qui apaise ?"

      Réponds directement comme The Bartender.
    PROMPT
  end

  def recommendation_instructions(cocktail)
    <<~PROMPT
      #{SYSTEM_PROMPT}

      Étape actuelle :
      Recommandation.

      Tu dois maintenant recommander ce cocktail précis :
      #{cocktail.name}

      Règles strictes :
      - Commence par "Je te propose un #{cocktail.name}." ou "Je partirais sur un #{cocktail.name}."
      - Explique en 1 ou 2 phrases pourquoi il correspond au contexte de l'utilisateur.
      - Fais explicitement référence à au moins un élément donné par l'utilisateur dans la conversation.
      - Utilise les informations de l'historique de conversation.
      - Ne donne pas les ingrédients.
      - Ne donne pas la recette.
      - Ne termine pas par une question.
      - Ne propose aucun autre cocktail.
      - Réponds comme The Bartender.
    PROMPT
  end

  def message_with_conversation_history
    previous_messages = @chat.messages
                             .where.not(id: @message.id)
                             .where.not(content: [nil, ""])
                             .order(created_at: :desc)
                             .limit(12)
                             .reverse

    history = previous_messages.map do |message|
      speaker = message.role == "user" ? "Utilisateur" : "The Bartender"
      "#{speaker} : #{message.content}"
    end.join("\n\n")

    <<~PROMPT
      Historique récent de la conversation :

      #{history.presence || 'Aucun message précédent.'}

      Message actuel de l'utilisateur :
      #{@message.content}

      Réponds au message actuel en tenant compte de l'historique ci-dessus.
    PROMPT
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

  def clean_cocktail_name(name)
    name.to_s
        .lines
        .first
        .to_s
        .strip
        .gsub(/\A["“”'«\s\-0-9.)]+/, "")
        .gsub(/["“”'»\s]+\z/, "")
        .gsub(/\Aun\s+/i, "")
        .gsub(/\Aune\s+/i, "")
        .strip
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
