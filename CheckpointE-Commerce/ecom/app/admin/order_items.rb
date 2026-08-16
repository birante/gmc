ActiveAdmin.register OrderItem do
  menu parent: "E-Commerce", priority: 4, label: "Articles de Commande"
  # Specify parameters which should be permitted for assignment
  permit_params :order_id, :item_id, :item_variant_id, :quantity, :unit_price, :total_price

  # For security, limit the actions that should be available
  actions :all, except: [ :destroy ]

  # Add or remove filters to toggle their visibility
  filter :id
  filter :order
  filter :item
  filter :quantity
  filter :unit_price
  filter :total_price
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :order do |oi|
      link_to "##{oi.order_id}", admin_order_path(oi.order) if oi.order
    end
    column :item do |oi|
      link_to oi.item&.name, admin_item_path(oi.item) if oi.item
    end
    column "Variante" do |oi|
      oi.item_variant&.display_name if oi.item_variant
    end
    column "Boutique" do |oi|
      link_to oi.item&.shop&.name, admin_shop_path(oi.item.shop) if oi.item&.shop
    end
    column :quantity
    column :unit_price do |oi|
      number_to_currency(oi.unit_price, unit: oi.order&.currency&.symbol || "€")
    end
    column :total_price do |oi|
      number_to_currency(oi.total_price, unit: oi.order&.currency&.symbol || "€")
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row :order do |oi|
        link_to "##{oi.order_id}", admin_order_path(oi.order) if oi.order
      end
      row :item do |oi|
        link_to oi.item&.name, admin_item_path(oi.item) if oi.item
      end
      row :item_variant do |oi|
        if oi.item_variant
          "#{oi.item_variant.display_name} (SKU: #{oi.item_variant.sku})"
        end
      end
      row "Boutique" do |oi|
        link_to oi.item&.shop&.name, admin_shop_path(oi.item.shop) if oi.item&.shop
      end
      row :quantity
      row :unit_price do |oi|
        number_to_currency(oi.unit_price, unit: oi.order&.currency&.symbol || "€")
      end
      row :total_price do |oi|
        number_to_currency(oi.total_price, unit: oi.order&.currency&.symbol || "€")
      end
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :order
      f.input :item
      f.input :item_variant, collection: f.object.item ? f.object.item.variants : []
      f.input :quantity
      f.input :unit_price
      f.input :total_price, hint: "Calculé automatiquement: quantity × unit_price"
    end
    f.actions
  end
end
