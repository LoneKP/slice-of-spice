class RecipesController < ApplicationController

  def index
    @recipes = Recipe.trending(10)
  end

  # GET /recipes
  # Browse all master recipes
  def index
    @recipes = Recipe.order(updated_at: :desc)
  end

  # GET /recipes/:id
  def show
    @recipe = @user_recipe.recipe
  end

  # PATCH/PUT /recipes/:id
  def update
    if @user_recipe.update(update_user_recipe_params)
      redirect_to my_recipes_path, notice: "Your recipe settings were updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

end