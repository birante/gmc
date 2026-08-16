class AddActiveToLocalShopBanners < ActiveRecord::Migration[8.0]
  def change
    add_column :local_shop_banners, :active, :boolean, default: true, null: false
    add_index :local_shop_banners, :active
  end
end
