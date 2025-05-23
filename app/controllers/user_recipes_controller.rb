class UserRecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_recipe, only: %i[show update]

  def my_recipes
    @user_recipes = current_user.user_recipes
                                .includes(:recipe)
                                .order(created_at: :desc)
  end

  def new
    @user_recipe = UserRecipe.new
  end

  def create
    if params[:recipe_id].present?
      # Case 1: Creating from existing recipe ID
      @recipe = Recipe.find(params[:recipe_id])
      @user_recipe = current_user.user_recipes.build(recipe: @recipe)
      
      respond_to do |format|
        if @user_recipe.save
          format.turbo_stream { render :create_from_index }
          format.html { redirect_to my_recipes_path, notice: "Recipe added to your collection." }
        else
          format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash_message", locals: { notice: "Could not add recipe to your collection." }), status: :unprocessable_entity }
          format.html { redirect_to recipes_path, alert: "Could not add recipe to your collection." }
        end
      end
    else
      # Case 2: Creating from URL
      url = user_recipe_params[:url]
      @recipe = Recipe.find_or_initialize_by(url: url)
      
      if @recipe.new_record?
        Recipe::Sourcer.new(@recipe).update_recipe_with_original_info
      end
      
      @user_recipe = current_user.user_recipes.build(recipe: @recipe)

      respond_to do |format|
        if @recipe.save && @user_recipe.save
          format.turbo_stream { redirect_to my_recipes_path, notice: "Recipe added to your collection." }
          format.html { redirect_to my_recipes_path, notice: "Recipe added to your collection." }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'recipe-form',
              partial: 'user_recipes/form',
              locals: { user_recipe: @user_recipe }
            ), status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end
  end

  def show
    @recipe = @user_recipe.recipe
  end

  def update
    if @user_recipe.update(user_recipe_params)
      # turbo will happily handle a 204
      head :no_content
    else
      render json: @user_recipe.errors, status: :unprocessable_entity
    end
  end
  

  private

  def set_user_recipe
    @user_recipe = current_user.user_recipes.find(params[:id])
  end

  def user_recipe_params
    params.require(:user_recipe)
          .permit(:url, :include_in_meal_plan, :title, :personal_yield_count, :personal_yield_unit, :notes)
  end

  # def update_user_recipe_params
    
  # end
end