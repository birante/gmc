class CreatePlanRules < ActiveRecord::Migration[8.0]
  def change
    create_table :plan_rules do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :rule, null: false, foreign_key: true
      t.jsonb :value
      t.boolean :is_active

      t.timestamps
    end
  end
end
