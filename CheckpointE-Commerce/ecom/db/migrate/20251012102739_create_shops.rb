class CreateShops < ActiveRecord::Migration[8.0]
  def change
    create_table :shops do |t|
      t.references :vendor, null: false, foreign_key: true
      t.string :slug
      t.string :name
      t.string :address
      t.text :description
      t.string :primary_color
      t.string :secondary_color
      t.string :status
      t.string :code

      t.timestamps
    end
  end
end
