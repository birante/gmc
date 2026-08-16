class AddPromoFieldsToItemsAndVariants < ActiveRecord::Migration[8.0]
  def change
    # Champs au niveau Item (dates globales de promo)
    add_column :items, :is_on_sale, :boolean, default: false, null: false
    add_column :items, :sale_start_date, :datetime
    add_column :items, :sale_end_date, :datetime
    add_column :items, :sale_discount_percent, :decimal, precision: 5, scale: 2

    # Champs au niveau Variant (prix promo spécifique par variant)
    add_column :item_variants, :sale_price, :decimal, precision: 10, scale: 2

    add_index :items, :is_on_sale
    add_index :items, :sale_end_date
  end
end
