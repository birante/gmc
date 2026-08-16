class CreateShopSectors < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_sectors do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true

      t.timestamps
    end
  end
end
