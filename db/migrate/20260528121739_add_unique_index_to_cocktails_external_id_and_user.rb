class AddUniqueIndexToCocktailsExternalIdAndUser < ActiveRecord::Migration[8.1]
  def change
    add_index :cocktails,
              [:user_id, :external_id],
              unique: true,
              where: "external_id IS NOT NULL",
              name: "index_cocktails_on_user_id_and_external_id_unique"
  end
end
