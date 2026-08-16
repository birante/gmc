class RemoveSessionsForeignKey < ActiveRecord::Migration[8.0]
  def change
    # Supprimer la contrainte de clé étrangère vers users
    remove_foreign_key :sessions, :users, column: :sessionable_id if foreign_key_exists?(:sessions, :users, column: :sessionable_id)
  end
end
