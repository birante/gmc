ActiveAdmin.register OrderStatusHistory do
  menu parent: "E-Commerce", priority: 5, label: "Historique de Statut"
  permit_params :order_id, :status, :note, :location, :changed_by_type, :changed_by_id

  actions :all, except: [ :edit, :update, :destroy ]

  filter :order
  filter :status, as: :select, collection: %w[pending processing shipped delivered canceled]
  filter :changed_by_type, as: :select, collection: %w[User Vendor Employee]
  filter :created_at

  index do
    selectable_column
    id_column
    column :order
    column :status do |osh|
      status_tag osh.status_label, class: osh.status
    end
    column "Message" do |osh|
      osh.status_message
    end
    column :note
    column :location
    column "Modifié par" do |osh|
      osh.changed_by_name
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :order do |osh|
        link_to "Commande ##{osh.order_id}", admin_order_path(osh.order)
      end
      row :status do |osh|
        status_tag osh.status_label, class: osh.status
      end
      row "Message" do |osh|
        osh.status_message
      end
      row :note
      row :location
      row "Modifié par" do |osh|
        osh.changed_by_name
      end
      row "Type de modificateur" do |osh|
        osh.changed_by_type
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de l'historique" do
      f.input :order
      f.input :status, as: :select, collection: %w[pending processing shipped delivered canceled]
      f.input :note, as: :text
      f.input :location
      f.input :changed_by_type, as: :select, collection: %w[User Vendor Employee], include_blank: true
      f.input :changed_by_id, label: "ID du modificateur"
    end
    f.actions
  end
end
