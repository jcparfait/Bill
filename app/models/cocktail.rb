class Cocktail < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :nullify

  validates :name, presence: true
  validates :ingredients, presence: true
  validates :recipe, presence: true
  validates :mood, presence: true
  validates :external_id, presence: true
  validates :image_url, presence: true
end
