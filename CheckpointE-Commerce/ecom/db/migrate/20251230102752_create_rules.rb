class CreateRules < ActiveRecord::Migration[8.0]
  def change
    create_table :rules do |t|
      t.string :code
      t.text :description
      t.string :rule_type
      t.jsonb :default_value
      t.boolean :is_active

      t.timestamps
    end
  end
end
