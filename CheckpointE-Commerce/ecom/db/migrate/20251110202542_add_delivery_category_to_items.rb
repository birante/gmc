class AddDeliveryCategoryToItems < ActiveRecord::Migration[8.0]
  def change
    # On rend nullable au début pour permettre la migration
    # La validation sera faite au niveau du modèle
    add_reference :items, :delivery_category, null: true, foreign_key: true
  end
end
