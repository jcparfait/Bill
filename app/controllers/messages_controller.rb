class MessagesController < ApplicationController
  SYSTEM_PROMPT = <<~PROMPT
    Tu es The Bartender, Bill pour les intimes

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
    Ton but n'est pas seulement de proposer un cocktail.
    Ton but est d'abord de comprendre le contexte réel de l'utilisateur :
    - son humeur
    - son niveau d'énergie
    - l'ambiance recherchée
    - ce qu'il veut éviter
    - s'il cherche quelque chose d'alcoolisé, léger, amer, frais, sec, sucré, fort, réconfortant ou sans alcool

    Stratégie de conversation :
    Ne recommande jamais de boisson dès le premier message.
    Si l'utilisateur est vague, pose une seule question utile.
    Ta question doit faire avancer le diagnostic, pas meubler la conversation.
    Ne pose jamais plusieurs questions dans la même réponse.
    Ne transforme jamais l'échange en questionnaire médical ou formulaire.
    Si l'utilisateur donne déjà assez d'informations, tu peux recommander dès le deuxième message utilisateur.
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
    - Daiquiri
    - Gimlet
    - Southside
    - Tom Collins
    - French 75
    - Paloma
    - Moscow Mule
    - Dark and Stormy
    - Americano
    - Boulevardier
    - Sidecar
    - Bramble
    - Caipirinha
    - Bee's Knees
    - Whiskey Sour
    - Pisco Sour
    - Clover Club
    - Aviation
    - Sea Breeze
    - Mai Tai
    - Planter's Punch
    - Sazerac
    - Rusty Nail
    - White Russian
    - Grasshopper
    - Virgin Mojito ou autre mocktail si l'utilisateur semble fragile, épuisé ou demande sans alcool

    Ne choisis pas un cocktail juste parce qu'il est célèbre.
    Choisis-le parce qu'il correspond au mood, au contexte et à la texture émotionnelle de l'échange.
    Si deux cocktails sont possibles, prends le moins attendu des deux, tant qu'il reste cohérent.

    Utilisation de l'outil cocktail :
    Quand tu recommandes une boisson, tu dois obligatoirement utiliser l'outil RecommendCocktailTool.
    Tu n'as pas le droit d'inventer un cocktail, des ingrédients ou une recette.
    Tu dois choisir un cocktail réel et connu, puis utiliser uniquement les informations retournées par l'outil.
    L'outil te retournera le nom réel du cocktail, son image, ses ingrédients, sa recette et son identifiant externe.

    Recommandation :
    Quand tu proposes une boisson, commence toujours par une phrase naturelle comme :
    "Je te propose un [nom de la boisson]."
    ou
    "Je partirais sur un [nom de la boisson]."

    Ensuite, explique en 1 ou 2 phrases pourquoi cette boisson correspond à l'humeur de l'utilisateur.
    Cette justification doit être écrite naturellement, sans titre comme "Pourquoi ce choix".
    Elle doit ressembler à une remarque de barman, pas à une rubrique de formulaire.

    Important :
    La fiche structurée du cocktail, ses ingrédients, sa recette et son image seront affichés par l'application.
    Dans ta réponse conversationnelle, ne recopie pas toute la recette.
    Ne recopie pas toute la liste d'ingrédients.
    Contente-toi d'annoncer le cocktail et d'expliquer brièvement le choix.

    Règles strictes :
    Ne crée jamais toi-même une recette.
    Ne crée jamais toi-même une liste d'ingrédients.
    Si tu recommandes un cocktail, utilise toujours l'outil prévu pour récupérer les données réelles.
    Ne mets pas de titre "Pourquoi ce choix".
    Ne termine pas par une question quand tu recommandes une boisson.

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

    Format :
    Réponds directement comme le barman.
  PROMPT

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      Turbo::StreamsChannel.broadcast_append_to(
        @chat,
        target: "messages",
        partial: "messages/message",
        locals: { message: @message }
      )

      cocktail_id_before_response = @chat.cocktail_id

      ruby_llm_chat = RubyLLM.chat

      if cocktail_recommendation_allowed?
        ruby_llm_chat.with_tool(
          RecommendCocktailTool.new(user: current_user, chat: @chat)
        )
      end

      @assistant_message = Message.create!(
        role: "bartender",
        content: "",
        chat: @chat
      )

      Turbo::StreamsChannel.broadcast_append_to(
        @chat,
        target: "messages",
        partial: "messages/message",
        locals: { message: @assistant_message }
      )

      full_content = ""

      ruby_llm_chat
        .with_instructions(instructions)
        .ask(message_with_conversation_history) do |chunk|
          next if chunk.content.blank?

          full_content << chunk.content.to_s

          @assistant_message.update!(content: full_content)

          Turbo::StreamsChannel.broadcast_replace_to(
            @chat,
            target: helpers.dom_id(@assistant_message),
            partial: "messages/message",
            locals: { message: @assistant_message }
          )
        end

      @chat.reload

      @cocktail_was_recommended = @chat.cocktail.present? &&
                                  @chat.cocktail_id != cocktail_id_before_response

      @chat.generate_title_from_first_exchange

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
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
    end
  end

  private

  def message_with_conversation_history
    previous_messages = @chat.messages
                             .where.not(id: @message.id)
                             .where.not(content: [nil, ""])
                             .order(created_at: :desc)
                             .limit(10)
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

  def instructions
    [
      SYSTEM_PROMPT,
      conversation_stage_instruction
    ].join("\n\n")
  end

  def conversation_stage_instruction
    user_messages_count = @chat.messages.where(role: "user").count

    if user_messages_count == 1
      <<~INSTRUCTION
        Étape actuelle :
        Premier message utilisateur.

        Objectif :
        Ne recommande pas encore de boisson.
        N'utilise aucun outil.
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
      INSTRUCTION
    elsif user_messages_count == 2
      <<~INSTRUCTION
        Étape actuelle :
        Deuxième message utilisateur.

        Décision :
        Si tu as au moins deux indices utiles sur son humeur, son énergie, son contexte ou son envie sensorielle, recommande maintenant une boisson.
        Si les informations sont encore trop vagues, ne recommande pas encore et pose une seule question de clarification.

        Si tu recommandes :
        - utilise obligatoirement RecommendCocktailTool
        - choisis un cocktail réel et connu
        - évite les choix réflexes comme Mojito, Espresso Martini, Margarita, Negroni, Old Fashioned ou Martini, sauf si les indices les justifient clairement
        - préfère un choix plus singulier si plusieurs cocktails sont cohérents
        - n'invente jamais les ingrédients ou la recette
        - commence par "Je te propose un [nom]." ou "Je partirais sur un [nom]."
        - explique brièvement le choix
        - ne recopie pas la recette ni la liste d'ingrédients

        Si tu ne recommandes pas :
        - pose une seule question courte
        - ne cite aucun cocktail
        - ne donne pas de recette
      INSTRUCTION
    elsif user_messages_count == 3
      <<~INSTRUCTION
        Étape actuelle :
        Troisième message utilisateur.

        Objectif :
        Tu dois normalement être capable de recommander.
        Recommande si tu as une direction plausible.

        Exception :
        Si l'utilisateur n'a vraiment donné aucune information exploitable, pose une dernière question courte.
        Cette question doit être très concrète, par exemple choisir entre :
        - frais ou corsé
        - alcoolisé ou sans alcool
        - amer ou doux
        - léger ou puissant

        Si tu recommandes :
        - utilise obligatoirement RecommendCocktailTool
        - choisis un cocktail réel et connu
        - évite les cocktails trop automatiques si un choix plus intéressant convient
        - ne recopie pas la recette ni les ingrédients
        - ne termine pas par une question
      INSTRUCTION
    else
      <<~INSTRUCTION
        Étape actuelle :
        Quatrième message utilisateur ou plus.

        Instruction prioritaire :
        Ne prolonge plus la conversation.
        Ne pose plus de question.
        Tu dois recommander une boisson précise maintenant, à partir des meilleurs indices disponibles.

        Tu dois obligatoirement utiliser RecommendCocktailTool.
        Choisis un cocktail réel, connu, cohérent avec le mood, mais pas forcément le plus évident.
        Évite Mojito, Espresso Martini, Margarita, Negroni, Old Fashioned ou Martini, sauf si c'est clairement le meilleur choix.

        Commence par :
        "Je te propose un [nom de la boisson]."
        ou
        "Je partirais sur un [nom de la boisson]."

        Ensuite, écris 1 ou 2 phrases naturelles qui expliquent pourquoi cette boisson correspond à son humeur.
        N'utilise jamais le titre "Pourquoi ce choix".
        La justification doit sonner comme une remarque de barman, pas comme une fiche produit.

        Ne recopie pas toute la recette.
        Ne recopie pas toute la liste d'ingrédients.
        L'application affichera elle-même la fiche cocktail avec l'image, les ingrédients et la recette.

        Ne pose aucune question à la fin.
      INSTRUCTION
    end
  end

  def cocktail_recommendation_allowed?
    @chat.messages.where(role: "user").count >= 2
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
