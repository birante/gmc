ActiveAdmin.register Subscription do
  menu parent: "Plans & Règles", priority: 3, label: "Abonnements"

  permit_params :shop_id, :plan_id, :status, :started_at, :ends_at

  actions :all, except: []

  action_item :edit_plan_rules, only: :show, if: proc { resource.plan.present? } do
    link_to "Éditer le plan et ses règles", edit_admin_plan_path(resource.plan)
  end

  action_item :shop_rule_overrides, only: :show do
    link_to "Overrides règles (boutique)", admin_shop_rules_path(q: { shop_id_eq: resource.shop_id })
  end

  filter :shop
  filter :plan
  filter :status
  filter :started_at
  filter :ends_at
  filter :created_at

  scope :all, default: true
  scope :active
  scope :expired
  scope :cancelled

  index do
    selectable_column
    id_column
    column :shop
    column :plan
    column :status do |subscription|
      status_tag subscription.status,
        class: case subscription.status
               when "active" then "ok"
               when "expired" then "error"
               when "cancelled" then "no"
               else "warning"
               end
    end
    column :started_at
    column :ends_at
    column "Durée restante" do |subscription|
      if subscription.ends_at && subscription.active?
        days = (subscription.ends_at.to_date - Date.today).to_i
        if days > 0
          span "#{days} jours", class: days < 7 ? "text-red-600" : "text-gray-600"
        else
          span "Expiré", class: "text-red-600 font-semibold"
        end
      else
        "-"
      end
    end
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :shop do |subscription|
        link_to subscription.shop.name, admin_shop_path(subscription.shop)
      end
      row :plan do |subscription|
        link_to subscription.plan.name, admin_plan_path(subscription.plan)
      end
      row :status do |subscription|
        status_tag subscription.status,
          class: case subscription.status
                 when "active" then "ok"
                 when "expired" then "error"
                 when "cancelled" then "no"
                 else "warning"
                 end
      end
      row :started_at
      row :ends_at
      row "Durée restante" do |subscription|
        if subscription.ends_at && subscription.active?
          days = (subscription.ends_at.to_date - Date.today).to_i
          if days > 0
            span "#{days} jours restants", class: days < 7 ? "text-red-600 font-semibold" : "text-gray-600"
          else
            span "Expiré", class: "text-red-600 font-semibold"
          end
        else
          "-"
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Règles appliquées (via le plan)" do
      if resource.plan
        table_for resource.plan.plan_rules.includes(:rule).order("rules.code") do
          column :rule do |plan_rule|
            link_to plan_rule.rule.code, admin_rule_path(plan_rule.rule)
          end
          column :value do |plan_rule|
            if plan_rule.value.nil?
              span "nil (illimité)", class: "text-gray-500"
            else
              plan_rule.value.to_s
            end
          end
        end
      else
        para "Aucun plan associé", class: "text-gray-500"
      end
    end

    panel "Overrides boutique (ShopRules)" do
      shop_rules = resource.shop.shop_rules.includes(:rule).order("rules.code")
      if shop_rules.any?
        table_for shop_rules do
          column :rule do |shop_rule|
            link_to shop_rule.rule.code, admin_rule_path(shop_rule.rule)
          end
          column :value do |shop_rule|
            if shop_rule.value.nil?
              span "nil (illimité)", class: "text-gray-500"
            else
              shop_rule.value.to_s
            end
          end
          column :is_active
        end
      else
        para "Aucun override pour cette boutique", class: "text-gray-500"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop
      f.input :plan
      f.input :status, as: :select, collection: [ "active", "expired", "cancelled" ]
      f.input :started_at, as: :string, input_html: { type: "datetime-local", value: f.object.started_at&.strftime("%Y-%m-%dT%H:%M") }
      f.input :ends_at,   as: :string, input_html: { type: "datetime-local", value: f.object.ends_at&.strftime("%Y-%m-%dT%H:%M") }
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:shop, :plan)
    end
  end
end
