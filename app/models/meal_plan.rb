# app/models/meal_plan.rb
class MealPlan < ApplicationRecord
  belongs_to :user
  has_many   :meal_plan_recipes, dependent: :destroy

  validates :start_date, :meals_per_week, :number_of_people, presence: true

  def generate!
    # Get all recipes that should be included
    pool = user.user_recipes
               .where(include_in_meal_plan: true)
               .order(:include_in_meal_plan_at)  # keeps append order if you're stamping them
               .to_a

    return if pool.empty?

    # Delete all existing meal plan recipes
    meal_plan_recipes.delete_all

    # Calculate the number of weeks needed
    total_recipes = pool.length
    weeks_needed = (total_recipes.to_f / meals_per_week).ceil

    monday = start_date.beginning_of_week(:monday)

    # Distribute recipes across weeks
    weeks_needed.times do |week_idx|
      week_start = monday + week_idx.weeks
      recipes_for_week = pool.shift(meals_per_week) || []
      
      recipes_for_week.each do |ur|
        meal_plan_recipes.create!(
          user_recipe: ur,
          scheduled_for_week_start_date: week_start
        )
      end
    end

    # Clean up any weeks that have more than meals_per_week entries
    cleanup_overflow_weeks
  end

  private

  def cleanup_overflow_weeks
    # Get all weeks that have more than meals_per_week entries
    overflow_weeks = meal_plan_recipes
      .group(:scheduled_for_week_start_date)
      .having("COUNT(*) > ?", meals_per_week)
      .pluck(:scheduled_for_week_start_date)

    overflow_weeks.each do |week_start|
      # Get all entries for this week, ordered by creation time
      entries = meal_plan_recipes
        .where(scheduled_for_week_start_date: week_start)
        .order(created_at: :asc)

      # Keep only the first meals_per_week entries
      entries.offset(meals_per_week).destroy_all
    end
  end
end