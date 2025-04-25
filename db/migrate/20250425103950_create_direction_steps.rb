class CreateDirectionSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :direction_steps do |t|
      t.references :direction_section, null: false, foreign_key: true
      t.text :text
      t.integer :position

      t.timestamps
    end
  end
end
