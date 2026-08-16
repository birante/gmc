class ChangeVendorStatusToString < ActiveRecord::Migration[8.0]
  def up
    # Change status column from boolean to string
    # First, add a temporary column
    add_column :vendors, :status_string, :string, default: "pending"

    # Migrate existing data: true -> "active", false/nil -> "pending"
    execute <<-SQL
      UPDATE vendors
      SET status_string = CASE
        WHEN status = true THEN 'active'
        WHEN status = false OR status IS NULL THEN 'pending'
        ELSE 'pending'
      END
    SQL

    # Remove old boolean column
    remove_column :vendors, :status

    # Rename new column to status
    rename_column :vendors, :status_string, :status

    # Add default constraint
    change_column_default :vendors, :status, "pending"
  end

  def down
    # Reverse migration: string -> boolean
    add_column :vendors, :status_boolean, :boolean, default: false

    # Migrate data: "active" -> true, others -> false
    execute <<-SQL
      UPDATE vendors
      SET status_boolean = CASE
        WHEN status = 'active' THEN true
        ELSE false
      END
    SQL

    remove_column :vendors, :status
    rename_column :vendors, :status_boolean, :status
  end
end
