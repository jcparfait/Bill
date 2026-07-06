class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :cocktail, optional: true
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy

  DEFAULT_TITLE = "Untitled"

  def display_title
    title == DEFAULT_TITLE ? "Conversation" : title.presence || "Conversation"
  end

  def generate_title_from_first_exchange
    return unless title == DEFAULT_TITLE

    user_messages = messages.where(role: "user").order(:created_at, :id).limit(3).pluck(:content)
    return if user_messages.size < 2

    update(title: generated_title(user_messages))
  end

  private

  def generated_title(user_messages)
    title = llm_title(user_messages) if llm_available?
    title = fallback_title(user_messages) if title.blank?

    clean_title(title)
  end

  def llm_title(user_messages)
    prompt = <<~PROMPT
      Résume cette conversation de bar en un titre français court.
      Contraintes:
      - 2 à 5 mots maximum
      - pas de guillemets
      - pas de ponctuation finale
      - ne mentionne pas Bill

      Messages utilisateur:
      #{user_messages.map { |content| "- #{content}" }.join("\n")}
    PROMPT

    RubyLLM.chat.ask(prompt).content.to_s
  rescue StandardError => e
    Rails.logger.warn "Chat title fallback: #{e.class} - #{e.message}"
    nil
  end

  def fallback_title(user_messages)
    text = I18n.transliterate(user_messages.join(" ").downcase.squish)

    return "Verre sans alcool" if text.match?(/sans alcool|mocktail|virgin|soft/)
    return "Besoin de détente" if text.match?(/detendre|relax|calme|fatigue|stress|tendu/)
    return "Envie de fraîcheur" if text.match?(/frais|fraicheur|citron|ete|chaud/)
    return "Cocktail réconfortant" if text.match?(/reconfort|doux|creme|sucre/)
    return "Verre de soirée" if text.match?(/soir|fete|amis|sortie/)

    "Conversation cocktail"
  end

  def clean_title(value)
    value.to_s.squish.delete_prefix("\"").delete_suffix("\"").delete_suffix(".").truncate(42, separator: " ")
  end

  def llm_available?
    ENV["GITHUB_TOKEN"].present? || ENV["OPENAI_API_KEY"].present?
  end
end
