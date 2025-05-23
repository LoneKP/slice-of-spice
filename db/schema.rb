# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_09_072815) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "direction_sections", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.string "name"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_direction_sections_on_recipe_id"
  end

  create_table "direction_steps", force: :cascade do |t|
    t.bigint "direction_section_id", null: false
    t.text "text"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["direction_section_id"], name: "index_direction_steps_on_direction_section_id"
  end

  create_table "ingredient_synonyms", force: :cascade do |t|
    t.bigint "ingredient_id", null: false
    t.string "locale"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_ingredient_synonyms_on_ingredient_id"
    t.index ["locale", "name"], name: "index_ingredient_synonyms_on_locale_and_name", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
  end

  create_table "meal_plan_recipes", force: :cascade do |t|
    t.bigint "meal_plan_id", null: false
    t.bigint "user_recipe_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.bigint "meal_plan_week_id"
    t.index ["meal_plan_id"], name: "index_meal_plan_recipes_on_meal_plan_id"
    t.index ["meal_plan_week_id"], name: "index_meal_plan_recipes_on_meal_plan_week_id"
    t.index ["user_recipe_id"], name: "index_meal_plan_recipes_on_user_recipe_id"
  end

  create_table "meal_plan_weeks", force: :cascade do |t|
    t.bigint "meal_plan_id", null: false
    t.date "start_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_plan_id", "start_date"], name: "index_meal_plan_weeks_on_meal_plan_id_and_start_date", unique: true
    t.index ["meal_plan_id"], name: "index_meal_plan_weeks_on_meal_plan_id"
  end

  create_table "meal_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "number_of_people", null: false
    t.integer "meals_per_week", null: false
    t.date "start_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_meal_plans_on_user_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 8, scale: 3
    t.string "unit"
    t.text "notes"
    t.integer "position"
    t.decimal "base_quantity", precision: 8, scale: 3
    t.string "base_unit"
    t.string "measure_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_title"
    t.string "image_url"
    t.integer "yield"
    t.string "language"
    t.string "yield_unit"
    t.integer "user_recipes_count", default: 0, null: false
    t.index ["user_recipes_count"], name: "index_recipes_on_user_recipes_count"
  end

  create_table "user_recipes", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "recipe_id"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "personal_yield_count"
    t.string "personal_yield_unit"
    t.integer "measurement_system"
    t.text "notes"
    t.boolean "include_in_meal_plan", default: false, null: false
    t.datetime "include_in_meal_plan_at"
    t.index ["recipe_id"], name: "index_user_recipes_on_recipe_id"
    t.index ["user_id"], name: "index_user_recipes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "direction_sections", "recipes"
  add_foreign_key "direction_steps", "direction_sections"
  add_foreign_key "ingredient_synonyms", "ingredients"
  add_foreign_key "meal_plan_recipes", "meal_plan_weeks"
  add_foreign_key "meal_plan_recipes", "meal_plans"
  add_foreign_key "meal_plan_recipes", "user_recipes"
  add_foreign_key "meal_plan_weeks", "meal_plans"
  add_foreign_key "meal_plans", "users"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
end
