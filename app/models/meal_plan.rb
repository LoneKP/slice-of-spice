# app/models/meal_plan.rb
class MealPlan < ApplicationRecord
  belongs_to :user
  has_many :meal_plan_weeks, dependent: :destroy
  has_many :meal_plan_recipes, dependent: :destroy

  validates :number_of_people, presence: true, numericality: { greater_than: 0 }
  validates :meals_per_week, presence: true, numericality: { greater_than: 0 }
  validates :start_date, presence: true

  def generate!
    # Get all recipes that should be included
    pool = user.user_recipes
               .where(include_in_meal_plan: true)
               .order(:include_in_meal_plan_at)  # keeps append order if you're stamping them
               .to_a

    return if pool.empty?

    # Delete all existing meal plan recipes and weeks
    meal_plan_recipes.delete_all
    meal_plan_weeks.delete_all

    # Calculate the number of weeks needed
    total_recipes = pool.length
    weeks_needed = (total_recipes.to_f / meals_per_week).ceil

    monday = start_date.beginning_of_week(:monday)

    # Distribute recipes across weeks
    weeks_needed.times do |week_idx|
      week_start = monday + week_idx.weeks
      
      # Create the week first
      week = meal_plan_weeks.create!(
        start_date: week_start
      )

      # Add recipes for this week
      recipes_for_week = pool.shift(meals_per_week) || []
      recipes_for_week.each_with_index do |ur, position|
        meal_plan_recipes.create!(
          meal_plan_week: week,
          user_recipe: ur,
          position: position
        )
      end
    end

    # Clean up any weeks that have more than meals_per_week entries
    cleanup_overflow_weeks
  end

  private

  def cleanup_overflow_weeks
    # Get all weeks that have more than meals_per_week entries
    overflow_weeks = meal_plan_weeks
      .joins(:meal_plan_recipes)
      .group('meal_plan_weeks.id')
      .having("COUNT(meal_plan_recipes.id) > ?", meals_per_week)
      .pluck('meal_plan_weeks.id')

    overflow_weeks.each do |week_id|
      # Get all entries for this week, ordered by creation time
      entries = meal_plan_recipes
        .where(meal_plan_week_id: week_id)
        .order(created_at: :asc)

      # Keep only the first meals_per_week entries
      entries.offset(meals_per_week).destroy_all
    end
  end
end