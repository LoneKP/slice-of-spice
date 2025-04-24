class UserRecipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_recipe, only: %i[show update]

  # GET /my_recipes
  def my_recipes
    @user_recipes = current_user.user_recipes
                                .includes(:recipe)
                                .order(created_at: :desc)
  end

  # GET /user_recipes/new
  def new
    @user_recipe = UserRecipe.new
  end

  # POST /user_recipes
  def create
    # 1) pull out the two attrs we need
    url, status = user_recipe_params.values_at(:url, :status)

    # 2) find or build the "master" recipe by URL
    @recipe = Recipe.find_or_initialize_by(url: url)

    # 3) if it's new, fire off your Sourcer to fill in title/image/ingredients/etc.
    if @recipe.new_record?
      Recipe::Sourcer.new(@recipe).update_recipe_with_original_info
    end

    # 4) build the join row
    @user_recipe = current_user.user_recipes.build(
      recipe: @recipe,
      status: status
    )
    respond_to do |format|
      
      if @recipe.save && @user_recipe.save
        format.turbo_stream           # renders create.turbo_stream.erb
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

  # GET /user_recipes/:id
  def show
    @recipe = @user_recipe.recipe
  end

  # PATCH/PUT /user_recipes/:id
  def update
    if @user_recipe.update(update_user_recipe_params)
      redirect_to my_recipes_path,
                  notice: "Your recipe settings were updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user_recipe
    @user_recipe = current_user.user_recipes.find(params[:id])
  end

  # NOTE: use :user_recipe (singular), not :users_recipe
  def user_recipe_params
    params.require(:user_recipe).permit(:url, :status)
  end

  def update_user_recipe_params
    params.require(:user_recipe).permit(:status)
  end
end