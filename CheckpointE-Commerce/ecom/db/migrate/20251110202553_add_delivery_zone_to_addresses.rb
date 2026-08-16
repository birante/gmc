class AddDeliveryZoneToAddresses < ActiveRecord::Migration[8.0]
  def change
    # On rend nullable car les adresses existantes n'auront pas de zone
    add_reference :addresses, :delivery_zone, null: true, foreign_key: true
  end
end
