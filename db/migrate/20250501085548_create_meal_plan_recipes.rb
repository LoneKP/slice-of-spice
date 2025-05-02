# db/migrate/20250501_create_meal_plan_recipes.rb
class CreateMealPlanRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_plan_recipes do |t|
      t.references :meal_plan,   null: false, foreign_key: true
      t.references :user_recipe, null: false, foreign_key: true
      t.date       :scheduled_for_week_start_date, null: false

      t.timestamps
    end

    add_index :meal_plan_recipes, [:meal_plan_id, :scheduled_for_week_start_date], unique: true, name: "index_mpr_on_plan_and_date"
  end
end
