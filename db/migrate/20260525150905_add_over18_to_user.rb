class AddOver18ToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :over18, :boolean
  end
end
