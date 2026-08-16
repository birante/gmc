class ChangeDefaultAISettingsInShops < ActiveRecord::Migration[8.0]
  def up
    # Changer les valeurs par défaut : ai_preview_enabled = true, ai_enabled = false
    change_column_default :shops, :ai_preview_enabled, from: false, to: true
    change_column_default :shops, :ai_enabled, from: true, to: false
  end

  def down
    # Revenir aux anciennes valeurs par défaut
    change_column_default :shops, :ai_preview_enabled, from: true, to: false
    change_column_default :shops, :ai_enabled, from: false, to: true
  end
end
