# app/models/meal_plan_recipe.rb
class MealPlanRecipe < ApplicationRecord
  belongs_to :meal_plan
  belongs_to :user_recipe

  validates :scheduled_for_week_start_date, presence: true
  validates :user_recipe_id,
            uniqueness: {
              scope: [:meal_plan_id, :scheduled_for_week_start_date],
              message: "is already in this week’s plan"
            }
end
