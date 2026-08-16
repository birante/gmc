ActiveAdmin.register DeliveryCategory do
  menu parent: "Logistique", priority: 2, label: "Catégories de Livraison"
  # Specify parameters which should be permitted for assignment
  permit_params :name, :code, :size, :description, :display_order

  # For security, limit the actions that should be available
  actions :all

  controller do
    def scoped_collection
      super.includes(:items, :delivery_prices)
    end
  end

  # Add or remove filters to toggle their visibility
  filter :id
  filter :code
  filter :name
  filter :size
  filter :description
  filter :display_order
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :code
    column :name
    column :size
    column :description
    column :display_order do |category|
      status_tag category.display_order, class: "info"
    end
    column "Articles" do |category|
      category.items.count
    end
    column "Prix configurés" do |category|
      category.delivery_prices.count
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :code
      row :name
      row :size
      row :description
      row :display_order do |category|
        status_tag category.display_order, class: "info"
      end
      row :created_at
      row :updated_at
    end

    panel "Prix de livraison par zone" do
      table_for resource.delivery_prices.includes(:delivery_zone) do
        column "Zone" do |dp|
          link_to dp.delivery_zone&.name, admin_delivery_zone_path(dp.delivery_zone) if dp.delivery_zone
        end
        column :price do |dp|
          number_to_currency(dp.price, unit: "€")
        end
      end
    end

    panel "Articles dans cette catégorie" do
      table_for resource.items.includes(:shop).limit(20) do
        column "Article" do |item|
          link_to item.name, admin_item_path(item)
        end
        column "Boutique" do |item|
          link_to item.shop&.name, admin_shop_path(item.shop) if item.shop
        end
        column :validation_status do |item|
          status_tag item.validation_status
        end
      end
    end

    panel "Statistiques" do
      attributes_table_for resource do
        row "Nombre total d'articles" do |category|
          category.items.count
        end
        row "Articles approuvés" do |category|
          category.items.where(validation_status: "approved").count
        end
      end
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :code, label: "Code", hint: "Code unique en minuscules (ex: standard, cargo)"
      f.input :name, label: "Nom de la catégorie"
      f.input :size, label: "Taille", hint: "Ex: Petit, Moyen, Grand"
      f.input :description, as: :text
      f.input :display_order, label: "Ordre d'affichage",
              hint: "Plus grand = catégorie prioritaire pour calcul des frais de livraison"
    end
    f.actions
  end
end
