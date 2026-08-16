# frozen_string_literal: true

class MaintenanceController < ApplicationController
  allow_unauthenticated_access
  layout "maintenance"

  def show
    @maintenance_notification = MaintenanceNotification.new
  end

  def create
    @maintenance_notification = MaintenanceNotification.new(maintenance_notification_params)

    if @maintenance_notification.save
      redirect_to maintenance_confirmation_path, notice: t("maintenance.notification_success", default: "Votre inscription a été prise en compte.")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def confirmation
    # Page de confirmation après inscription
  end

  private

  def maintenance_notification_params
    params.require(:maintenance_notification).permit(:first_name, :last_name, :email, :phone_number, :country_code, :user_type)
  end
end
