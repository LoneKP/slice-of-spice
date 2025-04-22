class RecipesController < ApplicationController
  before_action :authenticate_user!
  
  def my_recipes
    #added by me only
    @recipes = current_user.recipes.by_recently_created
  end

  def trending_recipes
    @recipe_sources = Recipe.joins(:recipe_source)
      .select('recipe_sources.*, COUNT(recipes.id) AS recipe_count')
      .group('recipe_sources.id')
      .having('COUNT(recipes.id) > 1')
      .order('recipe_count DESC')
  end
  
  def index
    @recipes = Recipe.by_recently_updated
  end

  def create
    recipe_source = RecipeSource.find_or_initialize_by(url: recipe_params[:url])
    @recipe       = Recipe.new
  
    if recipe_source.save
      @recipe.assign_attributes(
        user:  current_user,
        recipe_source: recipe_source,
        status: recipe_params[:status]
      )
    end
  
    respond_to do |format|
      if @recipe.save
        # ---------- SUCCESS ----------
        format.turbo_stream                     # looks for create.turbo_stream.erb
        format.html { redirect_to my_recipes_url,
                   notice: "Recipe was successfully created." }
      else
        # ---------- FAILURE -----------
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'recipe-form',
            partial: 'form',
            locals: { recipe: @recipe }
          ), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
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
