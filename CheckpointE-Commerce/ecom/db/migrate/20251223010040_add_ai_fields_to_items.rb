class AddAIFieldsToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :ai_enrichment_status, :string, default: "pending"
    add_column :items, :meta_title, :string
    add_column :items, :meta_description, :text
    add_column :items, :ai_generated_fields, :jsonb, default: {}

    add_index :items, :ai_enrichment_status
  end
end
