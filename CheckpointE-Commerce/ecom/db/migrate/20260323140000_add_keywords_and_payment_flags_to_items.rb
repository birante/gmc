# frozen_string_literal: true

class AddKeywordsAndPaymentFlagsToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :keywords, :text
    add_column :items, :cash_on_delivery_disabled, :boolean, default: false, null: false
    # Liste séparée par virgules : wave-senegal, orange-money-senegal, … (vide = pas de restriction)
    add_column :items, :allowed_payment_codes, :text
  end
end
