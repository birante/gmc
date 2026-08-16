class CreateSocialPlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :social_platforms do |t|
      t.string :code
      t.string :name
      t.string :icon_class
      t.boolean :is_active
      t.integer :position

      t.timestamps
    end
  end
end
