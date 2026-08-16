class MakeSessionsPolymorphic < ActiveRecord::Migration[8.0]
  def change
    # Renommer user_id en sessionable_id
    rename_column :sessions, :user_id, :sessionable_id

    # Ajouter le type polymorphe
    add_column :sessions, :sessionable_type, :string

    # Mettre à jour toutes les sessions existantes pour être de type User
    reversible do |dir|
      dir.up do
        execute "UPDATE sessions SET sessionable_type = 'User' WHERE sessionable_id IS NOT NULL"
      end
    end

    # Ajouter l'index polymorphe
    remove_index :sessions, :sessionable_id
    add_index :sessions, [ :sessionable_type, :sessionable_id ]
  end
end
