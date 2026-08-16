ActiveAdmin.register Rule do
  menu parent: "Plans & Règles", priority: 1, label: "Règles"

  permit_params :code, :description, :rule_type, :default_value, :is_active

  actions :all, except: []

  filter :code
  filter :rule_type
  filter :is_active
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :code
    column :description
    column :rule_type do |rule|
      status_tag rule.rule_type, class: rule.rule_type
    end
    column :default_value do |rule|
      if rule.default_value.nil?
        span "nil (illimité)", class: "text-gray-500"
      elsif rule.default_value.is_a?(Hash) || rule.default_value.is_a?(Array)
        code JSON.pretty_generate(rule.default_value), style: "font-size: 11px;"
      else
        rule.default_value.to_s
      end
    end
    column :is_active
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :code
      row :description
      row :rule_type
      row :default_value do |rule|
        if rule.default_value.nil?
          span "nil (illimité)", class: "text-gray-500"
        elsif rule.default_value.is_a?(Hash) || rule.default_value.is_a?(Array)
          pre JSON.pretty_generate(rule.default_value)
        else
          rule.default_value.to_s
        end
      end
      row :is_active
      row :created_at
      row :updated_at
    end

    panel "PlanRules associées" do
      table_for resource.plan_rules.includes(:plan) do
        column :plan do |plan_rule|
          link_to plan_rule.plan.name, admin_plan_path(plan_rule.plan)
        end
        column :value do |plan_rule|
          if plan_rule.value.nil?
            span "nil (illimité)", class: "text-gray-500"
          elsif plan_rule.value.is_a?(Hash) || plan_rule.value.is_a?(Array)
            code JSON.pretty_generate(plan_rule.value), style: "font-size: 11px;"
          else
            plan_rule.value.to_s
          end
        end
        column :is_active
        column :created_at
      end
    end

    panel "ShopRules associées" do
      table_for resource.shop_rules.includes(:shop).limit(10) do
        column :shop do |shop_rule|
          link_to shop_rule.shop.name, admin_shop_path(shop_rule.shop)
        end
        column :value do |shop_rule|
          if shop_rule.value.nil?
            span "nil (illimité)", class: "text-gray-500"
          elsif shop_rule.value.is_a?(Hash) || shop_rule.value.is_a?(Array)
            code JSON.pretty_generate(shop_rule.value), style: "font-size: 11px;"
          else
            shop_rule.value.to_s
          end
        end
        column :is_active
        column :created_at
      end
      if resource.shop_rules.count > 10
        para "Et #{resource.shop_rules.count - 10} autres...", class: "text-gray-500 text-sm"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :code
      f.input :description
      f.input :rule_type, as: :select, collection: [ "integer", "boolean", "string", "jsonb" ]
      f.input :default_value, as: :text, hint: "Pour JSON, utilisez la syntaxe JSON valide. Pour nil (illimité), laissez vide."
      f.input :is_active
    end
    f.actions
  end
end
