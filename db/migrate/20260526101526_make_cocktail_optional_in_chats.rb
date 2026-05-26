class MakeCocktailOptionalInChats < ActiveRecord::Migration[8.1]
  def change
    change_column_null :chats, :cocktail_id, true
  end
end
