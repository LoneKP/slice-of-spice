# app/controllers/meal_plan_controller.rb
class MealPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :load_or_initialize_plan, except: %i[create]

  def new
    # @meal_plan is already built but unsaved
    redirect_to edit_meal_plan_path if @meal_plan.persisted?
  end

  def edit
    redirect_to new_meal_plan_path unless @meal_plan.persisted?
  end
  
  def update
    # now @meal_plan is guaranteed to be set
    if @meal_plan.update(meal_plan_params)
      @meal_plan.generate!
      redirect_to meal_plan_path, notice: "Your meal plan was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    # build a new plan here
    @meal_plan = current_user.build_meal_plan(meal_plan_params)
    if @meal_plan.save
      @meal_plan.generate!
      redirect_to meal_plan_path, notice: "Your meal plan has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @meal_plan.persisted?
      @entries = @meal_plan.meal_plan_recipes.includes(:user_recipe)
    else
      redirect_to new_meal_plan_path, notice: "Let’s set up your first meal plan!"
    end
  end

  private

  def load_or_initialize_plan
    @meal_plan = current_user.meal_plan ||
                 current_user.build_meal_plan(
                   start_date: Date.today.beginning_of_week(:monday)
                 )
  end

  def meal_plan_params
    params.require(:meal_plan).permit(:number_of_people, :meals_per_week, :start_date)
  end
end