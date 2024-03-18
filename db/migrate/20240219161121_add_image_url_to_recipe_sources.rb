class AddImageUrlToRecipeSources < ActiveRecord::Migration[7.0]
  def change
    add_column :recipe_sources, :image_url, :string
  end
end
