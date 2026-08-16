class AddUniqueConstraintsToVendors < ActiveRecord::Migration[8.0]
  def change
    # Ajouter des indices uniques pour phone_number et email
    # Ces indices garantissent l'unicité au niveau de la base de données

    # Vérifier si les indices existent déjà (pour les migrations idempotentes)
    unless index_exists?(:vendors, :phone_number, unique: true)
      add_index :vendors, :phone_number, unique: true, name: "index_vendors_on_phone_number_unique"
    end

    unless index_exists?(:vendors, :email, unique: true)
      add_index :vendors, :email, unique: true, name: "index_vendors_on_email_unique"
    end
  end
end
