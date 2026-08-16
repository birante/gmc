class CreateShopLegalInfos < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_legal_infos do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :legal_form
      t.string :rc_number
      t.string :ninea_number

      t.timestamps
    end
  end
end
