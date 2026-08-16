class AddAverageRatingToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :average_rating, :decimal, precision: 3, scale: 2
    add_index :items, :average_rating
  end
end
