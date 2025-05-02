class FixMealPlanRecipesUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :meal_plan_recipes, name: "index_mpr_on_plan_and_date" rescue nil

    add_index :meal_plan_recipes,
              [:meal_plan_id, :scheduled_for_week_start_date, :user_recipe_id],
              unique: true,
              name: "index_mpr_plan_week_and_recipe"
  end
end
