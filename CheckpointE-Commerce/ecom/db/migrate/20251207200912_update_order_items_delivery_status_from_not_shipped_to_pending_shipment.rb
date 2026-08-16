class UpdateOrderItemsDeliveryStatusFromNotShippedToPendingShipment < ActiveRecord::Migration[8.0]
  def up
    # Mettre à jour tous les order_items avec delivery_status = 'not_shipped' vers 'pending_shipment'
    execute <<-SQL
      UPDATE order_items
      SET delivery_status = 'pending_shipment'
      WHERE delivery_status = 'not_shipped'
    SQL
  end

  def down
    # Revenir en arrière : remettre 'pending_shipment' vers 'not_shipped'
    execute <<-SQL
      UPDATE order_items
      SET delivery_status = 'not_shipped'
      WHERE delivery_status = 'pending_shipment'
    SQL
  end
end
