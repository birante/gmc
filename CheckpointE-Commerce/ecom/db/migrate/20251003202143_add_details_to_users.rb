class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def up
    # Ajouter les colonnes sans contraintes d'abord
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :country_code, :string
    add_column :users, :phone_number, :string

    # Remplir les valeurs par défaut pour les enregistrements existants
    User.update_all(country_code: 'SN')
    User.where(phone_number: nil).update_all(phone_number: '0000000000')

    # Maintenant ajouter les contraintes
    change_column_default :users, :country_code, 'SN'
    change_column_null :users, :country_code, false
    change_column_null :users, :phone_number, false
    change_column_null :users, :email_address, true
  end

  def down
    change_column_null :users, :email_address, false
    change_column_null :users, :phone_number, true
    change_column_null :users, :country_code, true
    change_column_default :users, :country_code, nil

    remove_column :users, :phone_number
    remove_column :users, :country_code
    remove_column :users, :last_name
    remove_column :users, :first_name
  end
end
