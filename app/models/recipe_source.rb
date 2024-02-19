class RecipeSource < ApplicationRecord
  include Sourced
  has_many :recipes

  after_commit :get_and_update_original_title, on: :create

  def get_and_update_original_title
    sourcer.update_recipe_source_with_original_title
  end
end