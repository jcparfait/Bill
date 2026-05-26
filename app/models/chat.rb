class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :cocktail, optional: true
  has_many :messages, dependent: :destroy
end
