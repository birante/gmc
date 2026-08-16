class CreateNewsletterSubscribers < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletter_subscribers do |t|
      t.string :email, limit: 255, null: false
      t.boolean :subscribed, default: true
      t.timestamps
    end

    add_index :newsletter_subscribers, :email, unique: true
  end
end
