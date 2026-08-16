class AddUniqueIndexesToOffersAndRules < ActiveRecord::Migration[8.0]
  def change
    # Règles
    add_index :rules, :code, unique: true unless index_exists?(:rules, :code)

    # Plans
    add_index :plans, :code, unique: true unless index_exists?(:plans, :code)

    # PlanRules (1 règle par plan)
    add_index :plan_rules,
              [ :plan_id, :rule_id ],
              unique: true,
              name: "index_plan_rules_on_plan_and_rule" unless index_exists?(:plan_rules, [ :plan_id, :rule_id ])

    # ShopRules (1 override max par boutique)
    add_index :shop_rules,
              [ :shop_id, :rule_id ],
              unique: true,
              name: "index_shop_rules_on_shop_and_rule" unless index_exists?(:shop_rules, [ :shop_id, :rule_id ])

    # AddOns
    add_index :add_ons, :code, unique: true unless index_exists?(:add_ons, :code)
  end
end
