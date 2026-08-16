class SocialPlatform < ApplicationRecord
  before_validation :set_default_position, on: :create

  private

  def set_default_position
    return if position.present?
    self.position = SocialPlatform.maximum(:position) + 1
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "is_active", "name", "position", "updated_at", "code", "icon_class" ]
  end
end
