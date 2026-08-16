# frozen_string_literal: true

ActiveAdmin.register Review do
  menu parent: "Catalogue", priority: 10, label: "Avis Clients"

  permit_params :user_id, :item_id, :order_item_id, :rating, :comment, :status, :images

  filter :user
  filter :item
  filter :rating
  filter :status, as: :select, collection: Review::STATUSES.map { |s| [ s.humanize, s ] }
  filter :helpful_count
  filter :created_at

  scope :all, default: true
  scope :approved
  scope :pending
  scope :rejected

  index do
    selectable_column
    id_column
    column "Client" do |review|
      link_to review.user.full_name, admin_user_path(review.user)
    end
    column "Produit" do |review|
      link_to review.item.name, admin_item_path(review.item)
    end
    column "Note" do |review|
      div do
        review.rating.times do
          span "⭐", style: "color: #fbbf24;"
        end
        (5 - review.rating).times do
          span "☆", style: "color: #d1d5db;"
        end
        span " (#{review.rating}/5)"
      end
    end
    column "Commentaire" do |review|
      truncate(review.comment, length: 50) if review.comment.present?
    end
    column "Statut" do |review|
      status_tag review.status,
        class: case review.status
               when "approved" then "ok"
               when "pending" then "warning"
               when "rejected" then "error"
               end
    end
    column "Utile", :helpful_count
    column "Commande" do |review|
      review.order_item ? link_to("##{review.order_item.order_id}", admin_order_path(review.order_item.order)) : "—"
    end
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :user do |review|
        link_to review.user.full_name, admin_user_path(review.user)
      end
      row :item do |review|
        link_to review.item.name, admin_item_path(review.item)
      end
      row "Note" do |review|
        div style: "display: flex; align-items: center; gap: 5px;" do
          review.rating.times do
            span "⭐", style: "color: #fbbf24; font-size: 20px;"
          end
          (5 - review.rating).times do
            span "☆", style: "color: #d1d5db; font-size: 20px;"
          end
          span " (#{review.rating}/5)", style: "font-weight: bold; margin-left: 10px;"
        end
      end
      row :comment do |review|
        simple_format(review.comment) if review.comment.present?
      end
      row :status do |review|
        status_tag review.status,
          class: case review.status
                 when "approved" then "ok"
                 when "pending" then "warning"
                 when "rejected" then "error"
                 end
      end
      row :helpful_count
      row :order_item do |review|
        if review.order_item
          link_to "Commande ##{review.order_item.order_id}", admin_order_path(review.order_item.order)
        else
          "—"
        end
      end
      row "Images" do |review|
        if review.images.attached?
          div style: "display: flex; gap: 10px; flex-wrap: wrap;" do
            review.images.each do |image|
              div do
                image_tag url_for(image), style: "max-width: 200px; max-height: 200px; border-radius: 8px; margin-top: 10px;"
              end
            end
          end
        else
          "Aucune image"
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Actions" do
      div style: "display: flex; gap: 10px; margin-top: 15px;" do
        if resource.pending?
          button_to "Approuver", approve_admin_review_path(resource), method: :post, class: "button", style: "background: #388e3c; color: white;"
          button_to "Rejeter", reject_admin_review_path(resource), method: :post, class: "button", style: "background: #d32f2f; color: white;"
        elsif resource.rejected?
          button_to "Approuver", approve_admin_review_path(resource), method: :post, class: "button", style: "background: #388e3c; color: white;"
        elsif resource.approved?
          button_to "Rejeter", reject_admin_review_path(resource), method: :post, class: "button", style: "background: #d32f2f; color: white;"
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :user
      f.input :item
      f.input :order_item, collection: OrderItem.order(created_at: :desc).limit(100).map { |oi| [ "Commande ##{oi.order_id} - #{oi.item.name}", oi.id ] }
      f.input :rating, as: :select, collection: (1..5).map { |r| [ "#{r} étoile#{'s' if r > 1}", r ] }
      f.input :comment, as: :text, input_html: { rows: 5 }
      f.input :status, as: :select, collection: Review::STATUSES.map { |s| [ s.humanize, s ] }
      f.input :images, as: :file, input_html: { multiple: true }, hint: "Photos du produit (optionnel, max 5 images)"

      if f.object.images.attached?
        f.inputs "Images actuelles" do
          div style: "display: flex; gap: 10px; flex-wrap: wrap; margin-top: 10px;" do
            f.object.images.each do |image|
              div do
                image_tag url_for(image), style: "max-width: 150px; max-height: 150px; border-radius: 8px;"
              end
            end
          end
        end
      end
    end
    f.actions
  end

  # Actions membres pour approuver/rejeter
  member_action :approve, method: :post do
    resource.update!(status: "approved")
    redirect_to admin_review_path(resource), notice: "Avis approuvé avec succès"
  end

  member_action :reject, method: :post do
    resource.update!(status: "rejected")
    redirect_to admin_review_path(resource), notice: "Avis rejeté"
  end

  # Action batch pour approuver plusieurs avis
  batch_action :approve do |ids|
    Review.where(id: ids).update_all(status: "approved", updated_at: Time.current)
    redirect_to collection_path, notice: "#{ids.count} avis approuvés"
  end

  # Action batch pour rejeter plusieurs avis
  batch_action :reject do |ids|
    Review.where(id: ids).update_all(status: "rejected", updated_at: Time.current)
    redirect_to collection_path, notice: "#{ids.count} avis rejetés"
  end
end
