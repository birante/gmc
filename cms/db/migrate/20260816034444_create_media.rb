class CreateMedia < ActiveRecord::Migration[8.1]
  def change
    create_table :media do |t|
      t.string :filename, null: false
      t.string :original_name
      t.string :file_path
      t.string :file_type
      t.integer :file_size
      t.string :mime_type
      t.references :uploaded_by, null: true, foreign_key: { to_table: :users }
      t.string :alt_text
      t.text :caption
      t.integer :width
      t.integer :height

      t.timestamps
    end
    add_index :media, :file_type
  end
end
