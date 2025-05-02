class EnforceOnePlanPerUser < ActiveRecord::Migration[8.0]
  def change
    remove_index :meal_plans, name: "index_meal_plans_on_user_id_and_start_date"
  end
end
