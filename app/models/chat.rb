class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :cocktail, optional: true
  has_many :messages, dependent: :destroy

  DEFAULT_TITLE = "Untitled"

  TITLE_PROMPT = <<~PROMPT
    Tu génères des titres courts pour des conversations avec un barman élégant, flegmatique et légèrement ironique.

    Le titre doit résumer l'ambiance émotionnelle de la conversation, pas seulement le sujet littéral.

    Ton :
    - sobre
    - élégant
    - légèrement mélancolique
    - un peu sec
    - jamais dramatique
    - jamais générique

    Règles :
    - Écris toujours en français
    - 3 à 6 mots maximum
    - Pas de guillemets
    - Pas de point final
    - Pas de titre générique comme "Discussion avec le barman"
    - Pas d'explication
    - Le titre doit ressembler au titre d'une scène calme dans un bar tard le soir

    Exemples :
    - Trop fatigué pour mentir
    - Une longue journée descend
    - Fraîcheur avant le silence
    - Nerveux avant la nuit
    - Mélancolie sans whisky
    - Pas triste juste vidé
    - Quelque chose de plus léger
    - Le calme après le bruit
  PROMPT

  def generate_title_from_first_exchange
    return unless title == DEFAULT_TITLE

    first_user_message = messages.where(role: "user").order(:created_at).first
    first_bartender_message = messages.where(role: "bartender").order(:created_at).first

    return if first_user_message.nil? || first_bartender_message.nil?

    title_context = <<~TEXT
      Message utilisateur :
      #{first_user_message.content}

      Réponse du barman :
      #{first_bartender_message.content}
    TEXT

    response = RubyLLM.chat
                      .with_instructions(TITLE_PROMPT)
                      .ask(title_context)

    update(title: response.content.strip)
  end
end
