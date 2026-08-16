# frozen_string_literal: true

# Aligne Employee#status sur Vendor#status : passage d'un booléen à un enum string
# ({ pending, active, suspended, inactive }). Les enregistrements existants
# true -> 'active', false -> 'inactive'.
class ChangeEmployeesStatusToString < ActiveRecord::Migration[8.0]
  def up
    remove_index :employees, :status if index_exists?(:employees, :status)

    # On supprime d'abord le default booléen pour pouvoir changer le type.
    change_column_default :employees, :status, from: true, to: nil
    execute(<<~SQL.squish)
      ALTER TABLE employees
      ALTER COLUMN status TYPE varchar
      USING (CASE WHEN status THEN 'active' ELSE 'inactive' END)
    SQL
    change_column_default :employees, :status, "active"
    change_column_null :employees, :status, false

    add_index :employees, :status
  end

  def down
    remove_index :employees, :status if index_exists?(:employees, :status)

    change_column_default :employees, :status, nil
    execute(<<~SQL.squish)
      ALTER TABLE employees
      ALTER COLUMN status TYPE boolean
      USING (status = 'active')
    SQL
    change_column_default :employees, :status, true
    change_column_null :employees, :status, false

    add_index :employees, :status
  end
end
