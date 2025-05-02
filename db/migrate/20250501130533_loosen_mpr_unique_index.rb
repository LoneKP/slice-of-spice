class LoosenMprUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :meal_plan_recipes, name: "index_mpr_on_plan_and_date"
    add_index    :meal_plan_recipes,
                 [:meal_plan_id, :scheduled_for_week_start_date],
                 name: "index_mpr_on_plan_and_date"
  end
end
