ActiveAdmin.register ShopAddOn do
  menu false

  permit_params :shop_id, :add_on_id, :quantity, :starts_at, :ends_at

  actions :all, except: []

  filter :shop
  filter :add_on
  filter :starts_at
  filter :ends_at
  filter :created_at

  scope :all, default: true
  scope :active
  scope :expired
  scope :upcoming

  index do
    selectable_column
    id_column
    column :shop do |shop_add_on|
      link_to shop_add_on.shop.name, admin_shop_path(shop_add_on.shop)
    end
    column :add_on do |shop_add_on|
      link_to shop_add_on.add_on.name, admin_add_on_path(shop_add_on.add_on)
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
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :shop do |shop_add_on|
        link_to shop_add_on.shop.name, admin_shop_path(shop_add_on.shop)
      end
      row :add_on do |shop_add_on|
        link_to shop_add_on.add_on.name, admin_add_on_path(shop_add_on.add_on)
      end
      row :quantity
      row :starts_at
      row :ends_at
      row "Statut" do |shop_add_on|
        if shop_add_on.ends_at && shop_add_on.ends_at < Time.current
          status_tag "Expiré", class: "error"
        elsif shop_add_on.starts_at && shop_add_on.starts_at > Time.current
          status_tag "À venir", class: "warning"
        else
          status_tag "Actif", class: "ok"
        end
      end
      row "Durée restante" do |shop_add_on|
        if shop_add_on.ends_at && shop_add_on.ends_at > Time.current
          days = (shop_add_on.ends_at.to_date - Date.today).to_i
          if days > 0
            span "#{days} jours restants", class: days < 7 ? "text-red-600 font-semibold" : "text-gray-600"
          else
            span "Expire aujourd'hui", class: "text-red-600 font-semibold"
          end
        else
          "-"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :shop
      f.input :add_on
      f.input :quantity, hint: "Quantité de l'add-on (ex: nombre de jours supplémentaires)"
      f.input :starts_at, as: :date_time_picker
      f.input :ends_at, as: :date_time_picker
    end
    f.actions
  end
end
