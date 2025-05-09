# app/controllers/meal_plans_controller.rb
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

  def add_week
    # Get the last week's start date
    last_week = @meal_plan.meal_plan_weeks
                         .order(start_date: :desc)
                         .first&.start_date

    if last_week
      new_week_start = last_week + 1.week
    else
      new_week_start = @meal_plan.start_date
    end

    # Create a new week
    respond_to do |format|
      format.turbo_stream do
        # Create a new week in the database
        week = @meal_plan.meal_plan_weeks.create!(
          start_date: new_week_start
        )

        render turbo_stream: turbo_stream.append(
          "meal_plan",
          partial: "meal_plans/week",
          locals: { 
            week: week,
            entries: week.meal_plan_recipes,
            meal_plan: @meal_plan
          }
        )
      end
    end
  end

  def update_entries
    Rails.logger.info "Updating entries with params: #{params.inspect}"
    
    begin
      week = @meal_plan.meal_plan_weeks.find_by!(id: params[:meal_plan_week_id])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error "Week not found for id: #{params[:meal_plan_week_id]}"
      render json: {
        status: "error",
        message: "Week not found"
      }, status: :not_found
      return
    end

    entries = params[:entries]
    Rails.logger.info "Processing #{entries.length} entries for week #{week.id}"

    begin
      ActiveRecord::Base.transaction do
        entries.each do |entry|
          Rails.logger.info "Processing entry: #{entry.inspect}"
          
          # First try to find the meal plan recipe in any week
          meal_plan_recipe = MealPlanRecipe.find_by(id: entry[:id])
          
          if meal_plan_recipe
            Rails.logger.info "Found existing meal plan recipe #{meal_plan_recipe.id}"
            Rails.logger.info "Updating to week #{week.id} at position #{entry[:position]}"
            
            # Update the existing recipe to the new week and position
            meal_plan_recipe.update!(
              meal_plan_week: week,
              position: entry[:position]
            )
          else
            Rails.logger.warn "Could not find meal plan recipe with id #{entry[:id]}"
            next # Skip this entry if we can't find the recipe
          end
        end
      end

      # Check if we're over the limit and include a warning in the response
      current_count = week.meal_plan_recipes.count
      warning = nil
      if current_count > @meal_plan.meals_per_week
        warning = "This week now has #{current_count} meals (limit is #{@meal_plan.meals_per_week})"
      end

      # Broadcast the update to refresh the view
      Rails.logger.info "Broadcasting update to meal_plan channel"
      Turbo::StreamsChannel.broadcast_replace_to(
        "meal_plan",
        target: "meal_plan",
        partial: "meal_plans/meal_plan_grid",
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
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        status: "error",
        message: e.message
      }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Rails.logger.error "Error occurred while processing entries: #{entries.inspect}"
      render json: {
        status: "error",
        message: "An unexpected error occurred: #{e.message}"
      }, status: :internal_server_error
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