class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :cocktail, optional: true
end
