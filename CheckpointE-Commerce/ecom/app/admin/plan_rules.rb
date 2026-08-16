ActiveAdmin.register PlanRule do
  menu parent: "Plans & Règles", priority: 4, label: "Règles de plan"

  permit_params :plan_id, :rule_id, :value, :is_active

  actions :all, except: []

  filter :plan
  filter :rule
  filter :is_active
  filter :created_at

  index do
    selectable_column
    id_column
    column :plan do |plan_rule|
      link_to plan_rule.plan.name, admin_plan_path(plan_rule.plan)
    end
    column :rule do |plan_rule|
      link_to plan_rule.rule.code, admin_rule_path(plan_rule.rule)
    end
    column :value do |plan_rule|
      if plan_rule.value.nil?
        span "nil (illimité)", class: "text-gray-500 font-semibold"
      elsif plan_rule.value.is_a?(Hash) || plan_rule.value.is_a?(Array)
        code JSON.pretty_generate(plan_rule.value), style: "font-size: 11px;"
      else
        plan_rule.value.to_s
      end
    end
    column :is_active
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :plan do |plan_rule|
        link_to plan_rule.plan.name, admin_plan_path(plan_rule.plan)
      end
      row :rule do |plan_rule|
        link_to plan_rule.rule.code, admin_rule_path(plan_rule.rule)
      end
      row :description do |plan_rule|
        plan_rule.rule.description
      end
      row :rule_type do |plan_rule|
        plan_rule.rule.rule_type
      end
      row :value do |plan_rule|
        if plan_rule.value.nil?
          span "nil (illimité)", class: "text-gray-500 font-semibold text-lg"
        elsif plan_rule.value.is_a?(Hash) || plan_rule.value.is_a?(Array)
          pre JSON.pretty_generate(plan_rule.value)
        else
          span plan_rule.value.to_s, class: "font-semibold"
        end
      end
      row :is_active
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :plan
      f.input :rule
      f.input :value, as: :text, hint: "Pour JSON, utilisez la syntaxe JSON valide. Pour nil (illimité), laissez vide. Pour boolean, utilisez true/false. Pour integer, utilisez un nombre."
      f.input :is_active
    end
    f.actions
  end
end
