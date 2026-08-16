ActiveAdmin.register SmsMessage do
  menu parent: "Paramètres Système", priority: 4, label: "SMS Messages"
  permit_params :to, :body, :status, :sms_type, :provider, :error_message

  actions :all, except: [ :edit, :update ]

  filter :to
  filter :status, as: :select, collection: SmsMessage::STATUSES
  filter :sms_type, as: :select, collection: SmsMessage::SMS_TYPES
  filter :provider, as: :select, collection: SmsMessage::PROVIDERS
  filter :created_at

  index do
    selectable_column
    id_column
    column :to
    column "Transaction ID" do |sms|
      sms.provider_response&.[]("transaction_id") || sms.provider_response&.[]("message_id")
    end
    column "LAM Status" do |sms|
      sms.provider_response&.dig("lam_callback", "status")
    end
    column "Message" do |sms|
      truncate(sms.body, length: 50)
    end
    column :status do |sms|
      status_tag sms.status_label, class: sms.status
    end
    column :sms_type
    column :provider
    column :error_message
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :to
      row "Transaction ID" do |sms|
        sms.provider_response&.[]("transaction_id") || sms.provider_response&.[]("message_id")
      end
      row "LAM Status" do |sms|
        sms.provider_response&.dig("lam_callback", "status")
      end
      row :body
      row :status do |sms|
        status_tag sms.status_label, class: sms.status
      end
      row :sms_type
      row :provider
      row :error_message
      row :provider_response do |sms|
        pre JSON.pretty_generate(sms.provider_response || {})
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Informations du SMS" do
      f.input :to
      f.input :body, as: :text
      f.input :status, as: :select, collection: SmsMessage::STATUSES
      f.input :sms_type, as: :select, collection: SmsMessage::SMS_TYPES, include_blank: true
      f.input :provider, as: :select, collection: SmsMessage::PROVIDERS, include_blank: true
      f.input :error_message
    end
    f.actions
  end
end
