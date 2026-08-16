# frozen_string_literal: true

ActiveAdmin.register PendingRegistration do
  menu parent: "Utilisateurs", priority: 4, label: "Inscriptions en attente"

  # Specify parameters which should be permitted for assignment
  permit_params :user_type, :email, :phone_number, :channel

  # For security, limit the actions that should be available
  # Note: Les PendingRegistration sont généralement créées automatiquement
  # par le système, donc on limite les actions aux lectures et suppressions
  actions :index, :show, :destroy

  # Add or remove filters to toggle their visibility
  filter :user_type, as: :select, collection: %w[User Vendor]
  filter :email
  filter :phone_number
  filter :channel, as: :select, collection: %w[sms email]
  filter :verified_at
  filter :otp_expires_at
  filter :created_at
  filter :updated_at

  # Scope pour filtrer par statut
  scope :all, default: true
  scope "Actifs", :active do |pending_registrations|
    pending_registrations.active
  end
  scope "Expirés", :expired do |pending_registrations|
    pending_registrations.expired
  end
  scope "Vérifiés", :verified do |pending_registrations|
    pending_registrations.verified
  end
  scope "Clients", :for_user do |pending_registrations|
    pending_registrations.for_user
  end
  scope "Vendeurs", :for_vendor do |pending_registrations|
    pending_registrations.for_vendor
  end

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column "Type" do |pending|
      status_tag pending.user_type, class: (pending.user_type == "User" ? "ok" : "warning")
    end
    column "Email" do |pending|
      pending.email.presence || "-"
    end
    column "Téléphone" do |pending|
      pending.phone_number.presence || "-"
    end
    column "Canal" do |pending|
      status_tag pending.channel, class: (pending.channel == "sms" ? "yes" : "no")
    end
    column "Statut" do |pending|
      if pending.verified?
        status_tag "Vérifié", class: "ok"
      elsif pending.expired?
        status_tag "Expiré", class: "error"
      else
        status_tag "Actif", class: "yes"
      end
    end
    column "Expire le" do |pending|
      pending.otp_expires_at
    end
    column "Créé le" do |pending|
      pending.created_at
    end
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table do
      row :id
      row "Type d'utilisateur" do |pending|
        status_tag pending.user_type, class: (pending.user_type == "User" ? "ok" : "warning")
      end
      row :email
      row :phone_number
      row "Canal d'envoi" do |pending|
        status_tag pending.channel, class: (pending.channel == "sms" ? "yes" : "no")
      end
      row "Code OTP" do |pending|
        # Masquer le code par sécurité sauf en développement
        if Rails.env.development?
          code "#{pending.otp_code} (visible uniquement en développement)"
        else
          "****** (masqué pour sécurité)"
        end
      end
      row "Expire le" do |pending|
        "#{pending.otp_expires_at} (#{time_ago_in_words(pending.otp_expires_at)})"
      end
      row "Statut" do |pending|
        if pending.verified?
          status_tag "Vérifié le #{pending.verified_at}", class: "ok"
        elsif pending.expired?
          status_tag "Expiré", class: "error"
        else
          status_tag "Actif", class: "yes"
        end
      end
      row :verified_at
      row :created_at
      row :updated_at
    end

    panel "Données d'inscription chiffrées" do
      if Rails.env.development?
        begin
          data = resource.registration_data
          attributes_table_for data do
            data.each do |key, value|
              row key do
                # Masquer les mots de passe
                if key.to_s.include?("password")
                  "****** (masqué)"
                else
                  value
                end
              end
            end
          end
        rescue => e
          div class: "flash flash_error" do
            "Erreur lors du déchiffrement: #{e.message}"
          end
        end
      else
        div class: "flash flash_notice" do
          "Les données chiffrées ne sont visibles qu'en développement pour des raisons de sécurité."
        end
      end
    end
  end

  # Actions personnalisées
  action_item :cleanup_expired, only: :index do
    link_to "Nettoyer les expirés", cleanup_expired_admin_pending_registrations_path,
            method: :post,
            data: { confirm: "Êtes-vous sûr de vouloir supprimer tous les enregistrements expirés ?" }
  end

  action_item :cleanup_verified, only: :index do
    link_to "Nettoyer les vérifiés", cleanup_verified_admin_pending_registrations_path,
            method: :post,
            data: { confirm: "Êtes-vous sûr de vouloir supprimer tous les enregistrements vérifiés de plus d'1 heure ?" }
  end

  collection_action :cleanup_expired, method: :post do
    count = PendingRegistration.cleanup_expired!
    redirect_to admin_pending_registrations_path, notice: "#{count} enregistrement(s) expiré(s) supprimé(s)."
  end

  collection_action :cleanup_verified, method: :post do
    count = PendingRegistration.cleanup_verified!
    redirect_to admin_pending_registrations_path, notice: "#{count} enregistrement(s) vérifié(s) supprimé(s)."
  end

  # Batch actions
  batch_action :destroy, confirm: "Êtes-vous sûr de vouloir supprimer ces enregistrements ?" do |ids|
    batch_action_collection.find(ids).each(&:destroy)
    redirect_to admin_pending_registrations_path, notice: "#{ids.count} enregistrement(s) supprimé(s)."
  end
end
