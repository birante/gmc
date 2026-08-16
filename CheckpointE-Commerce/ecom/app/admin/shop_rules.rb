ActiveAdmin.register ShopRule do
  menu parent: "Plans & Règles", priority: 5, label: "Règles boutique"

  permit_params :shop_id, :rule_id, :value, :is_active

  actions :all, except: []

  filter :shop
  filter :rule
  filter :is_active
  filter :created_at

  index do
    selectable_column
    id_column
    column :shop do |shop_rule|
      link_to shop_rule.shop.name, admin_shop_path(shop_rule.shop)
    end
    column :rule do |shop_rule|
      link_to shop_rule.rule.code, admin_rule_path(shop_rule.rule)
    end
    column :value do |shop_rule|
      if shop_rule.value.nil?
        span "nil (illimité)", class: "text-gray-500 font-semibold"
      elsif shop_rule.value.is_a?(Hash) || shop_rule.value.is_a?(Array)
        code JSON.pretty_generate(shop_rule.value), style: "font-size: 11px;"
      else
        shop_rule.value.to_s
      end
    end
    column :is_active
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :shop do |shop_rule|
        link_to shop_rule.shop.name, admin_shop_path(shop_rule.shop)
      end
      row :rule do |shop_rule|
        link_to shop_rule.rule.code, admin_rule_path(shop_rule.rule)
      end
      row :description do |shop_rule|
        shop_rule.rule.description
      end
      row :rule_type do |shop_rule|
        shop_rule.rule.rule_type
      end
      row :value do |shop_rule|
        if shop_rule.value.nil?
          span "nil (illimité)", class: "text-gray-500 font-semibold text-lg"
        elsif shop_rule.value.is_a?(Hash) || shop_rule.value.is_a?(Array)
          pre JSON.pretty_generate(shop_rule.value)
        else
          span shop_rule.value.to_s, class: "font-semibold"
        end
      end
      row :is_active, hint: "Désactiver pour revenir à la valeur du plan"
      row :created_at
      row :updated_at
    end

    panel "Valeur du plan (par défaut)" do
      plan_rule = resource.shop.current_subscription&.plan&.plan_rules&.find_by(rule: resource.rule)
      if plan_rule
        attributes_table_for plan_rule do
          row :plan do |pr|
            link_to pr.plan.name, admin_plan_path(pr.plan)
          end
          row :value do |pr|
            if pr.value.nil?
              span "nil (illimité)", class: "text-gray-500"
            else
              pr.value.to_s
            end
          end
        end
      else
        para "Aucun plan actif pour cette boutique", class: "text-gray-500"
      end
    end
  end

  form do |f|
    div class: "aa-admin-shop-rule-form", style: "max-width: 52rem;" do
      f.semantic_errors(*f.object.errors.attribute_names)
      f.inputs do
        f.input :shop
        f.input :rule
        f.input :value, as: :text, input_html: { rows: 10, style: "font-family: ui-monospace, monospace; font-size: 13px;" },
                hint: "Override de la valeur du plan. JSON valide si besoin. Vide = illimité (selon la règle)."
        f.input :is_active, hint: "Désactiver pour revenir à la valeur du plan"
      end
      f.actions
    end
  end
end
