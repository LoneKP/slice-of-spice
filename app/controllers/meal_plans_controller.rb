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
    if params[:entries].present?
      update_entries
    else
      if @meal_plan.update(meal_plan_params)
        @meal_plan.generate!
        redirect_to meal_plan_path, notice: "Your meal plan was updated."
      else
        render :edit, status: :unprocessable_entity
      end
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
      redirect_to new_meal_plan_path, notice: "Let's set up your first meal plan!"
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

  def update_entries
    Rails.logger.info "Updating entries with params: #{params.inspect}"
    
    begin
      week_start_date = Date.parse(params[:week_start_date])
    rescue Date::Error
      Rails.logger.error "Invalid date format: #{params[:week_start_date]}"
      render json: {
        status: "error",
        message: "Invalid date format"
      }, status: :unprocessable_entity
      return
    end

    entries = params[:entries]
    Rails.logger.info "Processing #{entries.length} entries for week starting #{week_start_date}"

    # Ensure the week start date is a Monday
    week_start_date = week_start_date.beginning_of_week(:monday)

    begin
      ActiveRecord::Base.transaction do
        entries.each do |entry|
          meal_plan_recipe = @meal_plan.meal_plan_recipes.find_by(id: entry[:id])
          if meal_plan_recipe
            Rails.logger.info "Updating meal plan recipe #{meal_plan_recipe.id} to week #{week_start_date}"
            meal_plan_recipe.update!(
              scheduled_for_week_start_date: week_start_date
            )
          else
            Rails.logger.warn "Could not find meal plan recipe with id #{entry[:id]}"
          end
        end
      end

      # Check if we're over the limit and include a warning in the response
      current_count = @meal_plan.meal_plan_recipes
                               .where(scheduled_for_week_start_date: week_start_date)
                               .count
      warning = nil
      if current_count > @meal_plan.meals_per_week
        warning = "This week now has #{current_count} meals (limit is #{@meal_plan.meals_per_week})"
      end

      # Broadcast the update to refresh the view
      Rails.logger.info "Broadcasting update to meal_plan channel"
      Turbo::StreamsChannel.broadcast_replace_to(
        "meal_plan",
        target: "meal_plan",
        partial: "meal_plans/meal_plan",
        locals: { meal_plan: @meal_plan.reload }
      )

      # Return the updated entries to confirm the change
      render json: {
        status: "success",
        message: "Meal plan updated successfully",
        warning: warning
      }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation error: #{e.message}"
      render json: {
        status: "error",
        message: e.message
      }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: {
        status: "error",
        message: "An unexpected error occurred"
      }, status: :internal_server_error
    end
  end
end