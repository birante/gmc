class ForceFixShopTypeValues < ActiveRecord::Migration[8.0]
  def up
    # Forcer la mise à jour de tous les shops avec shop_type NULL ou vide
    Shop.find_each do |shop|
      raw_value = shop.read_attribute(:shop_type)
      if raw_value.blank? || raw_value == '0'
        shop.update_column(:shop_type, 'local')
      end
    end

    # S'assurer que la valeur par défaut est bien 'local'
    change_column_default :shops, :shop_type, 'local'

    # Rendre la colonne non-nullable
    change_column_null :shops, :shop_type, false
  end

  def down
    change_column_null :shops, :shop_type, true
    change_column_default :shops, :shop_type, nil
  end
end
