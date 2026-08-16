class CreateShopSocialLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_social_links do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :social_platform, null: false, foreign_key: true
      t.string :url

      t.timestamps
    end
  end
end
