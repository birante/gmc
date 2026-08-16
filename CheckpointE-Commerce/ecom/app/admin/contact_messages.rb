ActiveAdmin.register ContactMessage do
  menu label: "Messages de contact", priority: 10

  permit_params :status

  actions :all, except: [ :new, :create ]

  scope :all, default: true
  scope("Nouveaux")    { |s| s.where(status: "new") }
  scope("En cours")    { |s| s.where(status: "in_progress") }
  scope("Traités")     { |s| s.where(status: "handled") }
  scope("Archivés")    { |s| s.where(status: "archived") }

  filter :first_name
  filter :last_name
  filter :email
  filter :subject
  filter :status, as: :select, collection: ContactMessage::STATUSES.map { |s| [ s.humanize, s ] }
  filter :created_at

  index do
    selectable_column
    id_column
    column "Nom", :full_name
    column :email
    column :phone
    column :subject
    column :status do |m|
      tag_class = case m.status
                  when "new"         then "warning"
                  when "in_progress" then "yes"
                  when "handled"     then "ok"
                  else "no"
                  end
      status_tag(m.status.humanize, class: tag_class)
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row "Nom complet", &:full_name
      row :email
      row :phone
      row :subject
      row :status
      row :message do |m|
        simple_format(m.message)
      end
      row :ip_address
      row :user_agent
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Statut" do
      f.input :status, as: :select,
              collection: ContactMessage::STATUSES.map { |s| [ s.humanize, s ] },
              include_blank: false
    end

    f.actions
  end
end
