class UpdateMealPlanRecipesForWeeks < ActiveRecord::Migration[7.1]
  def up
    # Add the new column
    add_reference :meal_plan_recipes, :meal_plan_week, foreign_key: true

    # Migrate existing data
    execute <<-SQL
      INSERT INTO meal_plan_weeks (meal_plan_id, start_date, created_at, updated_at)
      SELECT DISTINCT meal_plan_id, scheduled_for_week_start_date, NOW(), NOW()
      FROM meal_plan_recipes
      WHERE scheduled_for_week_start_date IS NOT NULL;
    SQL

    execute <<-SQL
      UPDATE meal_plan_recipes
      SET meal_plan_week_id = (
        SELECT id FROM meal_plan_weeks
        WHERE meal_plan_weeks.meal_plan_id = meal_plan_recipes.meal_plan_id
        AND meal_plan_weeks.start_date = meal_plan_recipes.scheduled_for_week_start_date
      )
      WHERE scheduled_for_week_start_date IS NOT NULL;
    SQL

    # Remove the old column
    remove_column :meal_plan_recipes, :scheduled_for_week_start_date
  end

  def down
    # Add back the old column
    add_column :meal_plan_recipes, :scheduled_for_week_start_date, :date

    # Migrate data back
    execute <<-SQL
      UPDATE meal_plan_recipes
      SET scheduled_for_week_start_date = (
        SELECT start_date FROM meal_plan_weeks
        WHERE meal_plan_weeks.id = meal_plan_recipes.meal_plan_week_id
      )
      WHERE meal_plan_week_id IS NOT NULL;
    SQL

    # Remove the new column
    remove_reference :meal_plan_recipes, :meal_plan_week
  end
end
