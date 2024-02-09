class AddTitleToRecipeSources < ActiveRecord::Migration[7.0]
  def change
    add_column :recipe_sources, :original_title, :string
  end
end
