# frozen_string_literal: true

module Notifications
  # Password notifications service
  class PasswordNotifications
    # Alias to PasswordResetNotification for backward compatibility
    def self.new(**kwargs)
      PasswordResetNotification.new(**kwargs)
    end
  end
end
