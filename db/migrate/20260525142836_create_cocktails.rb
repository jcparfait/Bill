class CreateCocktails < ActiveRecord::Migration[8.1]
  def change
    create_table :cocktails do |t|
      t.string :name
      t.text :ingredients
      t.text :recipe
      t.string :mood
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
