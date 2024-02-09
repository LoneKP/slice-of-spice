class CreateRecipeSources < ActiveRecord::Migration[7.0]
  def change
    create_table :recipe_sources do |t|
      t.string :url
      t.timestamps
    end
  end
end
