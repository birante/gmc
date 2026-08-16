ActiveAdmin.register Employee do
  menu parent: "Boutiques & Vendeurs", priority: 3, label: "Employés"

  # Specify parameters which should be permitted for assignment
  permit_params :vendor_id, :email, :first_name, :last_name, :phone_number,
                :country_code, :role, :status, :password, :password_confirmation

  # For security, limit the actions that should be available
  actions :all

  # Add or remove filters to toggle their visibility
  filter :id
  filter :vendor
  filter :email
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :role, as: :select, collection: Employee::ROLES.values
  filter :status, as: :select, collection: { "Actif" => "active", "Inactif" => "inactive", "En attente" => "pending", "Suspendu" => "suspended" }
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :vendor do |employee|
      link_to employee.vendor.full_name, admin_vendor_path(employee.vendor) if employee.vendor
    end
    column "Nom complet" do |employee|
      employee.full_name
    end
    column :email
    column "Téléphone" do |employee|
      employee.formatted_phone_number
    end
    column :role do |employee|
      employee.role_name
    end
    column "Boutiques" do |employee|
      employee.shop_names
    end
    column :status do |employee|
      if employee.active?
        status_tag("Actif", class: "ok")
      else
        status_tag("Inactif", class: "error")
      end
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :vendor do |employee|
        link_to employee.vendor.full_name, admin_vendor_path(employee.vendor) if employee.vendor
      end
      row "Nom complet" do |employee|
        employee.full_name
      end
      row :first_name
      row :last_name
      row :email
      row "Téléphone" do |employee|
        employee.formatted_phone_number
      end
      row :phone_number
      row :country_code
      row :role do |employee|
        employee.role_name
      end
      row :status do |employee|
        if employee.active?
          status_tag("Actif", class: "ok")
        else
          status_tag("Inactif", class: "error")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Boutiques assignées" do
      table_for resource.employee_shops.includes(:shop) do
        column "Boutique" do |es|
          link_to es.shop&.name, admin_shop_path(es.shop) if es.shop
        end
        column "Principale" do |es|
          if es.is_primary
            status_tag("Oui", class: "ok")
          else
            status_tag("Non")
          end
        end
        column "Date d'assignation" do |es|
          es.created_at
        end
      end
    end

    panel "Permissions" do
      attributes_table_for resource do
        row "Gérer les articles" do |employee|
          if employee.can_manage_items?
            status_tag("Oui", class: "ok")
          else
            status_tag("Non")
          end
        end
        row "Gérer les commandes" do |employee|
          if employee.can_manage_orders?
            status_tag("Oui", class: "ok")
          else
            status_tag("Non")
          end
        end
        row "Gérer l'inventaire" do |employee|
          if employee.can_manage_inventory?
            status_tag("Oui", class: "ok")
          else
            status_tag("Non")
          end
        end
        row "Voir les rapports" do |employee|
          if employee.can_view_reports?
            status_tag("Oui", class: "ok")
          else
            status_tag("Non")
          end
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de l'employé" do
      f.input :vendor
      f.input :first_name, label: "Prénom"
      f.input :last_name, label: "Nom"
      f.input :email
      f.input :phone_number, label: "Numéro de téléphone"
      f.input :country_code, label: "Code pays", hint: "Ex: 225 pour la Côte d'Ivoire"
      f.input :role, as: :select, collection: Employee::ROLES.invert, label: "Rôle"
      f.input :status, as: :select, collection: Employee.statuses.keys, label: "Statut", include_blank: false
    end

    f.inputs "Mot de passe" do
      if f.object.new_record?
        f.input :password, label: "Mot de passe", hint: "Au moins 8 caractères"
        f.input :password_confirmation, label: "Confirmation du mot de passe"
      else
        f.input :password, label: "Nouveau mot de passe", hint: "Laisser vide pour ne pas changer"
        f.input :password_confirmation, label: "Confirmation du nouveau mot de passe"
      end
    end

    f.actions
  end
end
