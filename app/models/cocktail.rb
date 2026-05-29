class Cocktail < ApplicationRecord
  belongs_to :user

  has_many :chats, dependent: :nullify
  has_many :messages, dependent: :nullify

  validates :name, presence: true
  validates :ingredients, presence: true
  validates :recipe, presence: true
  validates :mood, presence: true
  validates :external_id, uniqueness: { scope: :user_id }, allow_blank: true
end
