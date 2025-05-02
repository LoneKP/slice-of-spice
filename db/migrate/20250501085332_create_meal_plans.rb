# db/migrate/20250501_create_meal_plans.rb
class CreateMealPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_plans do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.integer    :number_of_people, null: false
      t.integer    :meals_per_week,   null: false
      t.date       :start_date,       null: false

      t.timestamps
    end

    add_index :meal_plans, [:user_id, :start_date], unique: true
  end
end
