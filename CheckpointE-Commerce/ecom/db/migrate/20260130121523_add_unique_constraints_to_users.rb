class AddUniqueConstraintsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Ajouter des indices uniques pour phone_number et email_address
    # Ces indices garantissent l'unicité au niveau de la base de données

    # Vérifier si les indices existent déjà (pour les migrations idempotentes)
    unless index_exists?(:users, :phone_number, unique: true)
      add_index :users, :phone_number, unique: true, name: "index_users_on_phone_number_unique"
    end

    unless index_exists?(:users, :email_address, unique: true)
      add_index :users, :email_address, unique: true, name: "index_users_on_email_address_unique"
    end
  end
end
