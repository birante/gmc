ActiveAdmin.register VendorVerification do
  menu parent: "Utilisateurs", priority: 3, label: "Vérifications Vendeurs"
  permit_params :vendor_id, :channel, :code, :expires_at, :status, :used_at

  actions :all, except: [ :edit, :update, :destroy ]

  filter :vendor
  filter :channel, as: :select, collection: VendorVerification::CHANNELS
  filter :code
  filter :status, as: :boolean
  filter :expires_at
  filter :used_at
  filter :created_at

  index do
    selectable_column
    id_column
    column :vendor
    column :channel do |vv|
      status_tag vv.channel.upcase, class: vv.channel
    end
    column :code
    column "Utilisé" do |vv|
      status_tag(vv.used? ? "Oui" : "Non", class: vv.used? ? "ok" : "no")
    end
    column :expires_at
    column :used_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :vendor do |vv|
        link_to vv.vendor.full_name, admin_vendor_path(vv.vendor)
      end
      row :channel do |vv|
        status_tag vv.channel.upcase, class: vv.channel
      end
      row :code
      row "Utilisé" do |vv|
        status_tag(vv.used? ? "Oui" : "Non", class: vv.used? ? "ok" : "no")
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
      f.input :vendor
      f.input :channel, as: :select, collection: VendorVerification::CHANNELS
      f.input :code
      f.input :expires_at, as: :string, input_html: { type: "datetime-local", value: f.object.expires_at&.strftime("%Y-%m-%dT%H:%M") }
      f.input :status, as: :boolean
      f.input :used_at,    as: :string, input_html: { type: "datetime-local", value: f.object.used_at&.strftime("%Y-%m-%dT%H:%M") }
    end
    f.actions
  end
end
