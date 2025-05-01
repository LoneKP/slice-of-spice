class RemoveStatusFromUserRecipes < ActiveRecord::Migration[8.0]
  def change
    remove_column :user_recipes, :status, :integer
  end
end
