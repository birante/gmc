class AddDescriptionToDeliveryZones < ActiveRecord::Migration[8.0]
  def up
    return if column_exists?(:delivery_zones, :description)

    add_column :delivery_zones, :description, :text
  end

  def down
    return unless column_exists?(:delivery_zones, :description)

    remove_column :delivery_zones, :description
  end
end
