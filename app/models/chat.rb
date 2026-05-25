class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :cocktail
  has_many :messages
end
