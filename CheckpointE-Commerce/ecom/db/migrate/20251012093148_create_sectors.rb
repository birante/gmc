class CreateSectors < ActiveRecord::Migration[8.0]
  def change
    create_table :sectors do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.boolean :is_active
      t.integer :position

      t.timestamps
    end
  end
end
