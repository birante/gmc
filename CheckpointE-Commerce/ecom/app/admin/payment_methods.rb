ActiveAdmin.register PaymentMethod do
  menu parent: "Paramètres Système", priority: 2, label: "Méthodes de Paiement"
  # Specify parameters which should be permitted for assignment
  permit_params :name, :description, :is_active, :display_order

  # For security, limit the actions that should be available
  actions :all

  # Add or remove filters to toggle their visibility
  filter :id
  filter :name
  filter :description
  filter :is_active, as: :select, collection: { "Actif" => true, "Inactif" => false }
  filter :display_order
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :name
    column :description
    column :display_order
    column "Paiements" do |method|
      Payment.where(payment_method_id: method.id).count
    end
    column :is_active do |method|
      if method.is_active
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
      row :name
      row :description
      row :display_order
      row :is_active do |method|
        if method.is_active
          status_tag("Actif", class: "ok")
        else
          status_tag("Inactif", class: "error")
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Statistiques" do
      attributes_table_for resource do
        row "Nombre de paiements" do |method|
          Payment.where(payment_method_id: method.id).count
        end
        row "Montant total des paiements" do |method|
          total = Payment.where(payment_method_id: method.id, status: :completed).sum(:amount)
          number_to_currency(total, unit: "€")
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name, label: "Nom de la méthode"
      f.input :description, as: :text
      f.input :display_order, label: "Ordre d'affichage", hint: "Plus petit = affiché en premier"
      f.input :is_active, as: :boolean, label: "Méthode active"
    end
    f.actions
  end
end
