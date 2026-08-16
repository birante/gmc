class FixShopTypeValues < ActiveRecord::Migration[8.0]
  def up
    # Corriger les valeurs shop_type qui seraient à '0' ou vides
    execute <<-SQL
      UPDATE shops#{' '}
      SET shop_type = CASE#{' '}
        WHEN id IN (SELECT shop_id FROM shop_legal_infos) THEN 'official'
        ELSE 'local'
      END
      WHERE shop_type IS NULL
         OR shop_type = ''
         OR shop_type = '0'
    SQL
  end

  def down
    # Pas de rollback nécessaire, c'est une correction de données
  end
end
