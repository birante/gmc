# frozen_string_literal: true

module Sms
  class LamCallbacksController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [ :delivery ]
    allow_unauthenticated_access only: [ :delivery ]

    # LAM callback for delivery status updates
    # Expected params: push_id, ret_id, to, status, text
    def delivery
      Rails.logger.info("[LamCallback] Delivery status received - params: #{params.to_unsafe_h}")

      to = params[:to].to_s
      text = params[:text].to_s
      status = params[:status].to_s

      normalized_to = PhoneNormalizerService.normalize(to, country_code: "SN") || to
      sms_message = find_sms_message(normalized_to, text)

      if sms_message
        update_sms_message_status(sms_message, status)
        sms_message.update!(
          provider_response: sms_message.provider_response.merge(
            "lam_callback" => {
              "push_id" => params[:push_id],
              "ret_id" => params[:ret_id],
              "to" => to,
              "status" => status,
              "text" => text
            }
          )
        )
        Rails.logger.info("[LamCallback] SmsMessage updated - id: #{sms_message.id} | status: #{sms_message.status}")
      else
        Rails.logger.warn("[LamCallback] No SmsMessage found for to=#{normalized_to} | text=#{text}")
      end

      render plain: "OK", status: :ok
    rescue StandardError => e
      Rails.logger.error("[LamCallback] Error - #{e.class.name}: #{e.message}")
      render plain: "ERROR", status: :unprocessable_entity
    end

    private

    def find_sms_message(to, text)
      SmsMessage.where(provider: "lam_service", to:).order(created_at: :desc).find do |message|
        message.body.to_s == text
      end
    end

    def update_sms_message_status(sms_message, lam_status)
      mapped = case lam_status.to_s.upcase
      when "SENT", "4", "DELIVRD", "6"
                 "sent"
      when "UNDELIVERED", "2", "REJECTD", "23", "EXPIRED", "12"
                 "failed"
      else
                 sms_message.status
      end

      sms_message.update!(status: mapped) if mapped != sms_message.status
    end
  end
end
