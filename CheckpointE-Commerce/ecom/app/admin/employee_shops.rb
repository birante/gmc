ActiveAdmin.register EmployeeShop do
  menu parent: "Boutiques & Vendeurs", priority: 9, label: "Employés Boutique"
  permit_params :employee_id, :shop_id, :is_primary

  actions :all

  filter :employee
  filter :shop
  filter :is_primary
  filter :created_at

  index do
    selectable_column
    id_column
    column :employee do |es|
      link_to es.employee.full_name, admin_employee_path(es.employee)
    end
    column :shop do |es|
      link_to es.shop.name, admin_shop_path(es.shop)
    end
    column "Boutique principale" do |es|
      status_tag(es.is_primary? ? "Oui" : "Non", class: es.is_primary? ? "ok" : "no")
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :employee do |es|
        link_to es.employee.full_name, admin_employee_path(es.employee)
      end
      row :shop do |es|
        link_to es.shop.name, admin_shop_path(es.shop)
      end
      row "Boutique principale" do |es|
        status_tag(es.is_primary? ? "Oui" : "Non", class: es.is_primary? ? "ok" : "no")
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Association Employé-Boutique" do
      f.input :employee
      f.input :shop
      f.input :is_primary, label: "Boutique principale", hint: "Cocher si c'est la boutique principale de l'employé"
    end
    f.actions
  end
end
