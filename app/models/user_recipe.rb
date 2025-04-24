class UserRecipe < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, counter_cache: true

  delegate :image_url, :original_title, to: :recipe

  enum :status, { want_to_cook: 0, cooked: 1 }

  #validates :user_recipe, 
  #uniqueness: { scope: :user_id, message: "You already added this recipe!"}

  #enum measurement_system: { metric: 0, imperial: 1 }
  # personal_yield_count, personal_yield_unit, notes
end