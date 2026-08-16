ActiveAdmin.register Plan do
  menu parent: "Plans & Règles", priority: 2, label: "Plans"

  permit_params :code, :name, :description, :is_custom, :is_active

  actions :all, except: []

  filter :code
  filter :name
  filter :is_custom
  filter :is_active
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :code
    column :name
    column :description
    column :is_custom do |plan|
      status_tag plan.is_custom ? "Oui" : "Non", class: plan.is_custom ? "yes" : "no"
    end
    column :is_active
    column "Règles" do |plan|
      plan.plan_rules.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :code
      row :name
      row :description
      row :is_custom
      row :is_active
      row :created_at
      row :updated_at
    end

    panel "Règles du plan" do
      table_for resource.plan_rules.includes(:rule).order("rules.code") do
        column :rule do |plan_rule|
          link_to plan_rule.rule.code, admin_rule_path(plan_rule.rule)
        end
        column :description do |plan_rule|
          plan_rule.rule.description
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
        column :actions do |plan_rule|
          link_to "Modifier", edit_admin_plan_rule_path(plan_rule), class: "button"
        end
      end
    end

    panel "Abonnements actifs" do
      table_for resource.subscriptions.active.includes(:shop).limit(10) do
        column :shop do |subscription|
          link_to subscription.shop.name, admin_shop_path(subscription.shop)
        end
        column :status
        column :started_at
        column :ends_at
        column :created_at
      end
      if resource.subscriptions.active.count > 10
        para "Et #{resource.subscriptions.active.count - 10} autres abonnements actifs...", class: "text-gray-500 text-sm"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :code
      f.input :name
      f.input :description
      f.input :is_custom, hint: "Cochez si c'est un plan personnalisé (ex: Partner)"
      f.input :is_active
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:plan_rules)
    end
  end
end
