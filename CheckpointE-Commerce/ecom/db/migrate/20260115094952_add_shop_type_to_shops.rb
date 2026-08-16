class AddShopTypeToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :shop_type, :string, default: 'local'
    add_index :shops, :shop_type

    # Migrer les données existantes : boutiques avec legal_info = officielles
    reversible do |dir|
      dir.up do
        Shop.reset_column_information
        Shop.joins(:legal_info).update_all(shop_type: 'official')
      end
    end
  end
end
