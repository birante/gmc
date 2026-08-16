# frozen_string_literal: true

module Client
  class OrderStatusMailer < ApplicationMailer
    # Envoie une notification au client lorsque sa commande passe en traitement
    def processing(order:)
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification traitement - order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Votre commande ##{order.order_number} est en cours de traitement"
      )
    end

    # Envoie une notification au client lorsque sa commande est expédiée
    def shipped(order:)
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification expédition - order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Votre commande ##{order.order_number} a été expédiée"
      )
    end

    # Envoie une notification au client lorsque sa commande est livrée
    def delivered(order:)
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification livraison - order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Votre commande ##{order.order_number} a été livrée"
      )
    end

    # Envoie une notification au client lorsque sa commande est annulée
    def canceled(order:)
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification annulation - order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Votre commande ##{order.order_number} a été annulée"
      )
    end

    # Envoie une notification au client lorsque sa commande est partiellement livrée
    def partial_delivery(order:)
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification livraison partielle - order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Votre commande ##{order.order_number} est partiellement livrée"
      )
    end

    # Envoie une notification au client lorsqu'un article de sa commande est expédié
    def item_shipped(order_item:, order:)
      @order_item = order_item
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification article expédié - order_item_id: #{order_item.id}, order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Un article de votre commande ##{order.order_number} a été expédié"
      )
    end

    # Envoie une notification au client lorsqu'un article de sa commande est livré
    def item_delivered(order_item:, order:)
      @order_item = order_item
      # Précharger order_items pour éviter les N+1 queries dans les vues
      @order = Order.includes(:order_items).find(order.id)
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification article livré - order_item_id: #{order_item.id}, order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Un article de votre commande ##{order.order_number} a été livré"
      )
    end

    # Envoie une notification au client lorsqu'un article de sa commande a échoué
    def item_failed(order_item:, order:)
      @order_item = order_item
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification article échoué - order_item_id: #{order_item.id}, order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Problème avec un article de votre commande ##{order.order_number}"
      )
    end

    # Envoie une notification au client lorsqu'un article de sa commande est retourné
    def item_returned(order_item:, order:)
      @order_item = order_item
      @order = order
      @user = order.user

      Rails.logger.info("📧 [Client::OrderStatusMailer] Envoi notification article retourné - order_item_id: #{order_item.id}, order_id: #{order.id}, user_id: #{@user.id}")

      mail(
        to: @user.email_address,
        subject: "Un article de votre commande ##{order.order_number} a été retourné"
      )
    end
  end
end
