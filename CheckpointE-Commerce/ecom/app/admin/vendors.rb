ActiveAdmin.register Vendor do
  menu parent: "Boutiques & Vendeurs", priority: 2, label: "Vendeurs"

  # Specify parameters which should be permitted for assignment
  permit_params :first_name, :last_name, :phone_number, :country_code, :email,
                :password, :password_confirmation, :status

  # For security, limit the actions that should be available
  actions :all

  # Add or remove filters to toggle their visibility
  filter :id
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :country_code
  filter :email
  filter :status, as: :select, collection: Vendor.statuses.keys
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column "Nom complet" do |vendor|
      vendor.full_name
    end
    column :email
    column "Téléphone" do |vendor|
      vendor.formatted_phone_number
    end
    column "Boutiques" do |vendor|
      vendor.shops_count_cache.to_i
    end
    column "Employés" do |vendor|
      vendor.employees_count_cache.to_i
    end
    column :status do |vendor|
      status_tag vendor.status, class: vendor.status
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row "Nom complet" do |vendor|
        vendor.full_name
      end
      row :first_name
      row :last_name
      row :email
      row "Téléphone" do |vendor|
        vendor.formatted_phone_number
      end
      row :phone_number
      row :country_code
      row :status do |vendor|
        status_tag vendor.status, class: vendor.status
      end
      row :created_at
      row :updated_at
    end

    panel "Boutiques" do
      table_for resource.shops do
        column "Nom" do |shop|
          link_to shop.name, admin_shop_path(shop)
        end
        column :code
        column :address
        column :status do |shop|
          status_tag shop.status, class: shop.status
        end
        column "Articles" do |shop|
          shop.items_count
        end
        column :created_at
      end
    end

    panel "Employés" do
      table_for resource.employees do
        column "Nom" do |employee|
          link_to employee.full_name, admin_employee_path(employee)
        end
        column :email
        column "Rôle" do |employee|
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
      end
    end

    if resource.vendor_verification
      panel "Vérification" do
        attributes_table_for resource.vendor_verification do
          row :verified do |vv|
            if vv.verified
              status_tag("Vérifié", class: "ok")
            else
              status_tag("Non vérifié", class: "error")
            end
          end
          row :verified_at
          row :verification_method
          row :verified_by
        end
      end
    end

    panel "Statistiques" do
      attributes_table_for resource do
        row "Nombre de boutiques" do |vendor|
          vendor.shops.size
        end
        row "Nombre d'employés" do |vendor|
          vendor.employees.count
        end
        row "Employés actifs" do |vendor|
          vendor.employees.where(status: true).count
        end
        row "Total articles" do |vendor|
          Item.joins(:shop).where(shops: { vendor_id: vendor.id }).count
        end
        row "Articles approuvés" do |vendor|
          Item.joins(:shop).where(shops: { vendor_id: vendor.id }, validation_status: "approved").count
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations du vendeur" do
      f.input :first_name, label: "Prénom"
      f.input :last_name, label: "Nom"
      f.input :email
      f.input :phone_number, label: "Numéro de téléphone"
      f.input :country_code, label: "Code pays", hint: "Ex: 225 pour la Côte d'Ivoire"
      f.input :status, as: :select, collection: Vendor.statuses.keys, label: "Statut"
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

  controller do
    # Précalcule shops/employees counts via UNE seule requête groupée pour éviter
    # les warnings Bullet "Need Counter Cache" sur l'index (1 SELECT par vendor sinon).
    def scoped_collection
      super
        .left_joins(:shops, :employees)
        .select("vendors.*, COUNT(DISTINCT shops.id) AS shops_count_cache, COUNT(DISTINCT employees.id) AS employees_count_cache")
        .group("vendors.id")
    end
  end
end
