class Session < ApplicationRecord
  belongs_to :sessionable, polymorphic: true

  # Alias pour compatibilité
  alias_method :user, :sessionable

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "ip_address", "updated_at", "user_agent", "sessionable_id", "sessionable_type" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "sessionable" ]
  end
end
