ActiveAdmin.register NewsletterSubscriber do
  permit_params :email, :subscribed

  index do
    selectable_column
    id_column
    column :email
    column :subscribed do |subscriber|
      status_tag(subscriber.subscribed? ? "Abonné" : "Désabonné", class: subscriber.subscribed? ? "ok" : "warning")
    end
    column :created_at
    column :updated_at
    actions
  end

  filter :email
  filter :subscribed
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email, required: true
      f.input :subscribed, label: "Abonné à la newsletter"
    end
    f.actions
  end

  action_item :delete_unsubscribed, only: :index do
    link_to "Supprimer les désabonnés", admin_newsletter_subscribers_path,
            method: :delete,
            data: { confirm: "Êtes-vous sûr?" },
            class: "text-red-600"
  end

  member_action :toggle_subscription, method: :patch do
    subscriber = NewsletterSubscriber.find(params[:id])
    subscriber.update(subscribed: !subscriber.subscribed?)
    redirect_to admin_newsletter_subscribers_path, notice: "Statut mis à jour"
  end

  action_item :toggle, only: :show do
    link_to(
      resource.subscribed? ? "Désabonner" : "Réabonner",
      admin_newsletter_subscriber_toggle_subscription_path(resource),
      method: :patch,
      class: resource.subscribed? ? "text-red-600" : "text-green-600"
    )
  end

  collection_action :export_csv, method: :get do
    subscribers = NewsletterSubscriber.subscribed.pluck(:email)
    csv_data = subscribers.join("\n")
    send_data csv_data,
              filename: "newsletter_subscribers_#{Date.today}.csv",
              type: "text/csv"
  end

  action_item :export, only: :index do
    link_to "Exporter CSV", export_csv_admin_newsletter_subscribers_path
  end
end
