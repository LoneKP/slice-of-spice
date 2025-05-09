class CreateMealPlanWeeks < ActiveRecord::Migration[7.1]
  def change
    create_table :meal_plan_weeks do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.date :start_date, null: false

      t.timestamps
    end

    add_index :meal_plan_weeks, [:meal_plan_id, :start_date], unique: true
  end
end
