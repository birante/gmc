class ChangeShopTypeDefaultToLocal < ActiveRecord::Migration[8.0]
  def up
    # Changer la colonne pour ajouter la valeur par défaut et rendre non-nullable
    change_column_default :shops, :shop_type, 'local'

    # Mettre à jour toutes les valeurs NULL ou vides
    execute <<-SQL
      UPDATE shops#{' '}
      SET shop_type = CASE#{' '}
        WHEN id IN (SELECT shop_id FROM shop_legal_infos) THEN 'official'
        ELSE 'local'
      END
      WHERE shop_type IS NULL OR shop_type = ''
    SQL

    # Rendre la colonne non-nullable
    change_column_null :shops, :shop_type, false
  end

  def down
    # Permettre NULL en cas de rollback
    change_column_null :shops, :shop_type, true
    change_column_default :shops, :shop_type, nil
  end
end
