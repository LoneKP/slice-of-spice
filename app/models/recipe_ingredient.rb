class RecipeIngredient < ApplicationRecord
  belongs_to :recipes
  belongs_to :ingredient
  # quantity, base_quantity, unit, notes, position, measure_type
end