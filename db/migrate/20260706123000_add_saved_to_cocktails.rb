class AddSavedToCocktails < ActiveRecord::Migration[8.1]
  def change
    add_column :cocktails, :saved, :boolean, null: false, default: true
  end
end
