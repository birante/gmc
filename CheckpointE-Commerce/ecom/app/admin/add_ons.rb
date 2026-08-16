# Enregistré sous un autre nom pour éviter "superclass mismatch for class AddOnsController"
# (le contrôleur généré sera AddOnOptionsController au lieu de AddOnsController)
ActiveAdmin.register AddOn, as: "AddOnOption" do
  menu false

  permit_params :code, :name, :description, :is_active

  actions :all, except: []

  filter :code
  filter :name
  filter :is_active
  filter :created_at

  index do
    selectable_column
    id_column
    column :code
    column :name
    column :description
    column :is_active
    column "Boutiques" do |add_on|
      add_on.shop_add_ons.count
    end
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :code
      row :name
      row :description
      row :is_active
      row :created_at
      row :updated_at
    end

    panel "Boutiques utilisant cet add-on" do
      table_for resource.shop_add_ons.includes(:shop).limit(20) do
        column :shop do |shop_add_on|
          link_to shop_add_on.shop.name, admin_shop_path(shop_add_on.shop)
        end
        column :quantity
        column :starts_at
        column :ends_at
        column "Statut" do |shop_add_on|
          if shop_add_on.ends_at && shop_add_on.ends_at < Time.current
            status_tag "Expiré", class: "error"
          elsif shop_add_on.starts_at && shop_add_on.starts_at > Time.current
            status_tag "À venir", class: "warning"
          else
            status_tag "Actif", class: "ok"
          end
        end
        column :created_at
      end
      if resource.shop_add_ons.count > 20
        para "Et #{resource.shop_add_ons.count - 20} autres...", class: "text-gray-500 text-sm"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :code
      f.input :name
      f.input :description
      f.input :is_active
    end
    f.actions
  end
end
