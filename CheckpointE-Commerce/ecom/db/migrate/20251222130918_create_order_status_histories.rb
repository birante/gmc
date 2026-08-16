class CreateOrderStatusHistories < ActiveRecord::Migration[8.0]
  def change
    # Vérifier si la table existe déjà (peut arriver si créée manuellement ou via schema:load)
    unless table_exists?(:order_status_histories)
      create_table :order_status_histories do |t|
        t.references :order, null: false, foreign_key: true
        t.string :status
        t.text :note
        t.string :changed_by_type
        t.bigint :changed_by_id
        t.string :location
        t.timestamps
      end

      add_index :order_status_histories, [ :changed_by_type, :changed_by_id ], name: "index_order_status_histories_on_changed_by"
      add_index :order_status_histories, :created_at, name: "index_order_status_histories_on_created_at"
      add_index :order_status_histories, [ :order_id, :status ], name: "index_order_status_histories_on_order_and_status"
    end
  end
end
