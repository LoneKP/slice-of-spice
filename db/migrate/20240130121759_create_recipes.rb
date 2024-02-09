class CreateRecipes < ActiveRecord::Migration[7.0]
  def change
    create_table :recipes do |t|
      t.belongs_to :user
      t.belongs_to :recipe_source
      t.integer :status
      t.string :title
      
      t.timestamps
    end
  end
end
