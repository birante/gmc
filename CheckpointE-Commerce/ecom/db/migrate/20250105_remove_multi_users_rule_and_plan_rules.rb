class RemoveMultiUsersRuleAndPlanRules < ActiveRecord::Migration[8.0]
  def up
    # Cette migration doit rester robuste même si la table n'existe plus
    unless table_exists?(:rules)
      say "Table rules absente, migration ignorée", true
      return
    end

    multi_users_rule_id = select_value(<<~SQL.squish)
      SELECT id
      FROM rules
      WHERE code = 'multi_users'
      LIMIT 1
    SQL

    return unless multi_users_rule_id.present?

    if table_exists?(:plan_rules)
      execute <<~SQL.squish
        DELETE FROM plan_rules
        WHERE rule_id = #{quote(multi_users_rule_id)}
      SQL
    end

    execute <<~SQL.squish
      DELETE FROM rules
      WHERE id = #{quote(multi_users_rule_id)}
    SQL

    say "Règle 'multi_users' et ses PlanRules supprimées avec succès", true
  end

  def down
    # Après cette migration, impossible de revenir en arrière sans données
    # Cette migration est destructive et ne doit pas être révertie en production
    raise ActiveRecord::IrreversibleMigration, "Cette migration supprime les données multi_users et ne peut pas être révertie"
  end
end
