class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :cocktail, optional: true
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy

  DEFAULT_TITLE = "Nouvelle conversation"
  LEGACY_DEFAULT_TITLE = "Untitled"

  def generate_title_from_first_exchange
    return unless [DEFAULT_TITLE, LEGACY_DEFAULT_TITLE].include?(title)

    first_user_message = messages.where(role: "user").order(:created_at).first
    return if first_user_message.nil?

    update(title: title_from(first_user_message.content))
  end

  private

  def title_from(content)
    text = content.to_s.squish
    return "Conversation avec Bill" if text.blank?

    text.truncate(42, separator: " ")
  end
end
