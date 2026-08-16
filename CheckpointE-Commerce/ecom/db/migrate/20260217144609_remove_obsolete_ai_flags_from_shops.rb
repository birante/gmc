class RemoveObsoleteAIFlagsFromShops < ActiveRecord::Migration[8.0]
  def change
    remove_column :shops, :ai_enabled, :boolean
    remove_column :shops, :ai_preview_enabled, :boolean
  end
end
