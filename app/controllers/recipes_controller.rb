class RecipesController < ApplicationController
  before_action :authenticate_user!
  
  def my_recipes
    #added by me only
    @recipes = current_user.recipes
  end

  def updates
    @recipes = Recipe.all
  end
  
  def index
    @recipes = Recipe.all
  end

  def create
    recipe_source = RecipeSource.find_or_create_by(url: recipe_params[:url])

    Recipe.create!(
      user_id: current_user.id,
      recipe_source_id: recipe_source.id,
      status:  recipe_params[:status]
    )

    redirect_to :index
  end

  def new
    @recipe = Recipe.new
  end

  def update
    recipe = Recipe.find(params[:id])
    recipe.update(recipe_params)
  end

  private

  def recipe_params
    params.require(:recipe).permit(:url, :status)
  end 

end
