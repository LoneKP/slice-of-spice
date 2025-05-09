# app/models/meal_plan_week.rb
class MealPlanWeek < ApplicationRecord
  belongs_to :meal_plan
  has_many :meal_plan_recipes, dependent: :destroy

  validates :start_date, presence: true
  validates :start_date, uniqueness: { scope: :meal_plan_id }

  def end_date
    start_date + 6.days
  end
end 