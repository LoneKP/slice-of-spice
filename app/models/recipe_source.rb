class RecipeSource < ApplicationRecord
  include Sourced, NumberOfUsers
  has_many :recipes, dependent: :destroy

  validates :url, presence: { message: "Paste the url of a recipe you want to add!"}

  after_commit :get_and_update_original_title, on: :create

  def get_and_update_original_title
    sourcer.update_recipe_source_with_original_title
  end
end