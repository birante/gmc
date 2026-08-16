ActiveAdmin.register MaintenanceNotification do
  # Specify parameters which should be permitted for assignment
  permit_params :first_name, :last_name, :email, :phone_number, :country_code, :user_type, :notified_at

  # For security, limit the actions that should be available
  actions :all, except: [ :destroy ] # On ne supprime pas les inscriptions, juste on les marque comme notifiées

  # Menu configuration
  menu priority: 12, label: "🔧 Maintenance"

  # Scopes pour filtrer rapidement
  scope :all, default: true
  scope :pending do |notifications|
    notifications.pending
  end
  scope :notified do |notifications|
    notifications.notified
  end
  scope :particuliers do |notifications|
    notifications.particuliers
  end
  scope :proprietaires_boutique do |notifications|
    notifications.proprietaires_boutique
  end

  # Add or remove filters to toggle their visibility
  filter :email
  filter :first_name
  filter :last_name
  filter :phone_number
  filter :country_code
  filter :user_type, as: :select, collection: MaintenanceNotification.user_types.map { |k, v| [ k.humanize, v ] }
  filter :notified_at
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :full_name do |notification|
      notification.full_name
    end
    column :email
    column :formatted_phone_number do |notification|
      notification.formatted_phone_number
    end
    column :user_type do |notification|
      status_tag notification.user_type_label,
                 class: (notification.particulier? ? :ok : :warning)
    end
    column :notified_at do |notification|
      if notification.notified_at
        status_tag "Notifié", class: :ok
      else
        status_tag "En attente", class: :warning
      end
    end
    column :created_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :full_name do |notification|
        notification.full_name
      end
      row :first_name
      row :last_name
      row :email
      row :phone_number
      row :country_code
      row :formatted_phone_number do |notification|
        notification.formatted_phone_number
      end
      row :user_type do |notification|
        status_tag notification.user_type_label,
                   class: (notification.particulier? ? :ok : :warning)
      end
      row :notified_at do |notification|
        if notification.notified_at
          "#{notification.notified_at.strftime('%d/%m/%Y à %H:%M')} (il y a #{distance_of_time_in_words(notification.notified_at, Time.current)})"
        else
          status_tag "Non notifié", class: :warning
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations personnelles" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :phone_number
      f.input :country_code
      f.input :user_type, as: :select, collection: MaintenanceNotification.user_types.map { |k, v| [ k.humanize, v ] }
    end
    f.inputs "Notification" do
      f.input :notified_at, as: :string, input_html: { type: "datetime-local", value: f.object.notified_at&.strftime("%Y-%m-%dT%H:%M") }
    end
    f.actions
  end

  # Action membre pour marquer comme notifié
  member_action :mark_as_notified, method: :put do
    resource.update(notified_at: Time.current)
    redirect_to admin_maintenance_notification_path(resource), notice: "Inscription marquée comme notifiée"
  end

  # Action batch pour marquer plusieurs comme notifiés
  batch_action :mark_as_notified do |ids|
    MaintenanceNotification.where(id: ids).update_all(notified_at: Time.current)
    redirect_to collection_path, notice: "#{ids.count} inscription(s) marquée(s) comme notifiée(s)"
  end

  # Action membre pour marquer comme non notifié
  member_action :mark_as_pending, method: :put do
    resource.update(notified_at: nil)
    redirect_to admin_maintenance_notification_path(resource), notice: "Inscription marquée comme en attente"
  end

  # Ajouter les actions personnalisées dans la page show
  action_item :mark_as_notified, only: :show, if: proc { !resource.notified_at } do
    link_to "Marquer comme notifié", mark_as_notified_admin_maintenance_notification_path(resource), method: :put, class: "button"
  end

  action_item :mark_as_pending, only: :show, if: proc { resource.notified_at } do
    link_to "Marquer comme en attente", mark_as_pending_admin_maintenance_notification_path(resource), method: :put, class: "button"
  end
end
