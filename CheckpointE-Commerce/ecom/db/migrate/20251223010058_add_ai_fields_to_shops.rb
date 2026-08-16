class AddAIFieldsToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :ai_enabled, :boolean, default: true
    add_column :shops, :ai_preview_enabled, :boolean, default: false
  end
end
