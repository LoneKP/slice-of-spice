class Ingredient < ApplicationRecord
  has_many :ingredient_synonyms, dependent: :destroy
  has_many :recipe_ingredients,   dependent: :destroy
  has_many :recipes, through: :recipe_ingredients
end