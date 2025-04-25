class IngredientSynonym < ApplicationRecord
  belongs_to :ingredient
  # columns: locale, name
  validates :name, uniqueness: { scope: :locale }
end
