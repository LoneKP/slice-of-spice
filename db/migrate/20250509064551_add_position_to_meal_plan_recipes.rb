class AddPositionToMealPlanRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :meal_plan_recipes, :position, :integer
  end
end
