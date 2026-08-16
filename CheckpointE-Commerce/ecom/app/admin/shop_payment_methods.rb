ActiveAdmin.register ShopPaymentMethod do
  menu parent: "Boutiques & Vendeurs", priority: 8, label: "Méthodes de Paiement Boutique"
  permit_params :shop_id, :payment_method_id, :is_active

  actions :all

  filter :shop
  filter :payment_method
  filter :is_active
  filter :created_at

  index do
    selectable_column
    id_column
    column :shop do |spm|
      link_to spm.shop.name, admin_shop_path(spm.shop)
    end
    column :payment_method
    column "Actif" do |spm|
      status_tag(spm.is_active? ? "Oui" : "Non", class: spm.is_active? ? "ok" : "no")
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :shop do |spm|
        link_to spm.shop.name, admin_shop_path(spm.shop)
      end
      row :payment_method
      row "Actif" do |spm|
        status_tag(spm.is_active? ? "Oui" : "Non", class: spm.is_active? ? "ok" : "no")
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Méthode de paiement de la boutique" do
      f.input :shop
      f.input :payment_method
      f.input :is_active
    end
    f.actions
  end
end
