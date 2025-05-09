# app/models/meal_plan_recipe.rb
class MealPlanRecipe < ApplicationRecord
  belongs_to :meal_plan
  belongs_to :meal_plan_week
  belongs_to :user_recipe, optional: true

  validates :position, presence: true
  validates :user_recipe_id,
            uniqueness: {
              scope: :meal_plan_week_id,
              message: "is already in this week's plan"
            },
            allow_nil: true
end
