class Cocktail < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :ingredients, presence: true
  validates :recipe, presence: true
  validates :mood, presence: true
end
