class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :code
      t.string :name
      t.text :description
      t.boolean :is_custom
      t.boolean :is_active

      t.timestamps
    end
  end
end
