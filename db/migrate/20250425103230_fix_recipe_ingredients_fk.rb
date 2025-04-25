class FixRecipeIngredientsFk < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :recipe_ingredients, column: :recipe_id
    add_foreign_key    :recipe_ingredients, :recipes,       column: :recipe_id
  end
end
