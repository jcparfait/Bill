class AddApiFieldsToCocktails < ActiveRecord::Migration[8.1]
  def change
    add_column :cocktails, :external_id, :string
    add_column :cocktails, :image_url, :string
  end
end
