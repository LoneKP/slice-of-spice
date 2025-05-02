class UserRecipe < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true

  attribute :include_in_meal_plan, :boolean, default: false

  delegate :image_url, :original_title, to: :recipe

  after_update_commit :sync_meal_plan, if: :saved_change_to_include_in_meal_plan?

  private

  def sync_meal_plan
    # 1) stamp the include_at (or clear it)
    if include_in_meal_plan
      update_column(:include_in_meal_plan_at, Time.current)
    else
      update_column(:include_in_meal_plan_at, nil)
    end

    # 2) find or build the user's single meal_plan
    plan = user.meal_plan ||
           user.create_meal_plan!(
             start_date: Date.today.beginning_of_week(:monday),
             number_of_people: 1,        # choose your defaults
             meals_per_week:   3
           )

    # 3) regenerate *in place*
    plan.generate!
  end

  #validates :user_recipe, 
  #uniqueness: { scope: :user_id, message: "You already added this recipe!"}

  #enum measurement_system: { metric: 0, imperial: 1 }
  # personal_yield_count, personal_yield_unit, notes
end