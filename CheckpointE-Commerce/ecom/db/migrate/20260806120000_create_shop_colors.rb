class CreateShopColors < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_colors do |t|
      t.references :shop, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :hex_code, null: false, limit: 7
      t.integer :position, default: 0, null: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :shop_colors, [ :shop_id, :name ],
              unique: true,
              where: "archived_at IS NULL",
              name: "index_shop_colors_on_shop_and_name_active"
    add_index :shop_colors, [ :shop_id, :position ]
  end
end
