class AddTrackingFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :departure_date, :datetime
    add_column :orders, :estimated_arrival_date, :datetime
  end
end
