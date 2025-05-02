class AddIncludedAtToUserRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :user_recipes, :include_in_meal_plan_at, :datetime
  end
end
