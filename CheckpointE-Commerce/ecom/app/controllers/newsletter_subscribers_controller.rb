class NewsletterSubscribersController < ApplicationController
  allow_unauthenticated_access

  def create
    email = params[:email].to_s.strip.downcase

    # Validate email format
    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: {
        success: false,
        message: t("newsletter.invalid_email", default: "Adresse email invalide")
      }, status: :unprocessable_entity
    end

    # Find or create subscriber
    subscriber = NewsletterSubscriber.find_or_create_by(email: email) do |ns|
      ns.subscribed = true
    end

    # Re-subscribe if was unsubscribed
    if subscriber.persisted? && !subscriber.subscribed?
      subscriber.update(subscribed: true)
      return render json: {
        success: true,
        message: t("newsletter.resubscribed", default: "Vous avez été réabonné à notre newsletter!")
      }
    end

    if subscriber.valid?
      render json: {
        success: true,
        message: t("newsletter.success", default: "Merci! Vérifiez votre email pour confirmer votre inscription.")
      }
    else
      render json: {
        success: false,
        message: subscriber.errors.full_messages.first || t("newsletter.error", default: "Une erreur est survenue")
      }, status: :unprocessable_entity
    end
  end
end
