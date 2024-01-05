class CreateSlices < ActiveRecord::Migration[7.0]
  def change
    create_table :slices do |t|
      t.string :url
      t.string :title
      t.timestamps
    end
  end
end
