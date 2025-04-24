# db/migrate/20250425_create_full_schema.rb
class CreateFullSchema < ActiveRecord::Migration[8.0]
  def change
    # Enable PG’s plpgsql extension (if not already enabled)
    enable_extension "plpgsql" unless extension_enabled?("plpgsql")

    # Ingredients & synonyms
    create_table :ingredients do |t|
      t.string   :name
      t.timestamps null: false
    end
    add_index :ingredients, :name, unique: true

    create_table :ingredient_synonyms do |t|
      t.references :ingredient, null: false, foreign_key: true, type: :bigint
      t.string     :locale
      t.string     :name
      t.timestamps null: false
    end
    add_index :ingredient_synonyms, [:locale, :name], unique: true

    # Users
    create_table :users do |t|
      t.string   :email,                  default: "", null: false
      t.string   :encrypted_password,     default: "", null: false
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string   :name
      t.timestamps null: false
    end
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true

    # Master recipes
    create_table :recipes do |t|
      t.string  :url
      t.string  :original_title
      t.string  :image_url
      t.string  :ingredients
      t.string  :directions
      t.integer :yield
      t.string  :language
      t.string  :yield_unit
      t.integer :user_recipes_count, default: 0, null: false
      t.timestamps null: false
    end
    add_index :recipes, :user_recipes_count

    # Per-user saved recipes (the join)
    create_table :user_recipes do |t|
      t.references :user,                 null: false, foreign_key: true, type: :bigint
      t.references :recipe,               null: false, foreign_key: true, type: :bigint
      t.integer    :status
      t.string     :title
      t.float      :personal_yield_count
      t.string     :personal_yield_unit
      t.integer    :measurement_system
      t.text       :notes
      t.timestamps null: false
    end
    add_index :user_recipes, :user_id
    add_index :user_recipes, :recipe_id

    # Ingredients join to recipes
    create_table :recipe_ingredients do |t|
      t.references :recipe,     null: false, foreign_key: true, type: :bigint
      t.references :ingredient, null: false, foreign_key: true, type: :bigint
      t.decimal    :quantity,       precision: 8, scale: 3
      t.string     :unit
      t.text       :notes
      t.integer    :position
      t.decimal    :base_quantity,  precision: 8, scale: 3
      t.string     :base_unit
      t.string     :measure_type
      t.timestamps null: false
    end
    add_index :recipe_ingredients, :recipe_id
    add_index :recipe_ingredients, :ingredient_id
  end
end
