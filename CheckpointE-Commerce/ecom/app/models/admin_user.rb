# frozen_string_literal: true

class AdminUser < ApplicationRecord
  has_secure_password

  ROLES = %w[admin manager].freeze

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  def admin?
    role == "admin"
  end

  def manager?
    role == "manager"
  end

  def display_name
    email
  end
end
