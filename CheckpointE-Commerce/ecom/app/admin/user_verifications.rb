ActiveAdmin.register UserVerification do
  menu parent: "Utilisateurs", priority: 2, label: "Vérifications Clients"
  permit_params :user_id, :channel, :code, :expires_at, :status, :used_at

  actions :all, except: [ :edit, :update, :destroy ]

  filter :user
  filter :channel, as: :select, collection: UserVerification::CHANNELS
  filter :code
  filter :status, as: :boolean
  filter :expires_at
  filter :used_at
  filter :created_at

  index do
    selectable_column
    id_column
    column :user
    column :channel do |uv|
      status_tag uv.channel.upcase, class: uv.channel
    end
    column :code
    column "Utilisé" do |uv|
      status_tag(uv.used? ? "Oui" : "Non", class: uv.used? ? "ok" : "no")
    end
    column :expires_at
    column :used_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user do |uv|
        link_to uv.user.full_name, admin_user_path(uv.user)
      end
      row :channel do |uv|
        status_tag uv.channel.upcase, class: uv.channel
      end
      row :code
      row "Utilisé" do |uv|
        status_tag(uv.used? ? "Oui" : "Non", class: uv.used? ? "ok" : "no")
      end
      row :status
      row :expires_at
      row :used_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations de vérification" do
      f.input :user
      f.input :channel, as: :select, collection: UserVerification::CHANNELS
      f.input :code
      f.input :expires_at, as: :string, input_html: { type: "datetime-local", value: f.object.expires_at&.strftime("%Y-%m-%dT%H:%M") }
      f.input :status, as: :boolean
      f.input :used_at,    as: :string, input_html: { type: "datetime-local", value: f.object.used_at&.strftime("%Y-%m-%dT%H:%M") }
    end
    f.actions
  end
end
