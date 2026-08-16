class FixShopTypeNullValues < ActiveRecord::Migration[8.0]
  def up
    # Mettre à jour toutes les valeurs NULL ou vides en 'local' par défaut
    execute <<-SQL
      UPDATE shops
      SET shop_type = 'local'
      WHERE shop_type IS NULL#{' '}
         OR shop_type = ''
         OR shop_type = '0'
    SQL

    # S'assurer que la valeur par défaut est bien 'local'
    change_column_default :shops, :shop_type, 'local'

    # Rendre la colonne non-nullable si ce n'est pas déjà fait
    change_column_null :shops, :shop_type, false
  end

  def down
    # Permettre NULL en cas de rollback
    change_column_null :shops, :shop_type, true
    change_column_default :shops, :shop_type, nil
  end
end
