# db/migrate/20250501_add_include_to_user_recipes.rb
class AddIncludeToUserRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :user_recipes, :include_in_meal_plan, :boolean, default: false, null: false
  end
end
