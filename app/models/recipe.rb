class Recipe < ApplicationRecord
  include Sourced

  #self.table_name = "recipes"

  has_many :recipe_ingredients, dependent: :destroy
  has_many :ingredients, through: :recipe_ingredients
  has_many :user_recipes, dependent: :destroy
  has_many :users, through: :user_recipes
  has_many :direction_sections, -> { order(:position) }, dependent: :destroy
  has_many :direction_steps, through: :direction_sections


  scope :trending, ->(n=10) { order(user_recipes_count: :desc).limit(n) }

  validates :url, presence: { message: "Paste the url of a recipe you want to add!"}

  after_commit :get_and_update_info, on: :create

  def get_and_update_info
    sourcer.update_recipe_with_original_info
  end
end