class AddCocktailToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :cocktail, null: true, foreign_key: true
  end
end
