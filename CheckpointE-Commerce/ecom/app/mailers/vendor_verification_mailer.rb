class VendorVerificationMailer < ApplicationMailer
  def otp_email(vendor = nil, code = nil)
    @vendor = vendor || params[:vendor]
    @code = code || params[:code]
    Rails.logger.info("📧 [VendorVerificationMailer] Envoi email OTP - vendor_id: #{@vendor.id}, email: #{@vendor.email}, code: #{@code}")
    mail(to: @vendor.email, subject: "Votre code de validation (#{Rails.application.config.vendor_otp.length} digits)")
  end
end
