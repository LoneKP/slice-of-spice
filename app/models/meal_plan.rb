# app/models/meal_plan.rb
class MealPlan < ApplicationRecord
  belongs_to :user
  has_many   :meal_plan_recipes, dependent: :destroy

  validates :start_date, :meals_per_week, :number_of_people, presence: true

  def generate!
    meal_plan_recipes.delete_all

    pool = user.user_recipes
               .where(include_in_meal_plan: true)
               .order(:include_in_meal_plan_at)  # keeps append order if you’re stamping them
               .to_a

    return if pool.empty?

    # break into week‐sized chunks (last chunk may be smaller)
    weeks = pool.each_slice(meals_per_week)

    monday = start_date.beginning_of_week(:monday)

    weeks.each_with_index do |recipes_for_week, idx|
      week_start = monday + idx.weeks

      recipes_for_week.each do |ur|
        meal_plan_recipes.create!(
          user_recipe:                   ur,
          scheduled_for_week_start_date: week_start
        )
      end
    end
  end
end