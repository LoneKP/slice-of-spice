class DeleteIngredientsAndDirectionsFromRecipe < ActiveRecord::Migration[8.0]
  def change
    remove_column :recipes, :ingredients, :string
    remove_column :recipes, :directions, :string
  end
end
