class Currency < ApplicationRecord
    scope :active, -> { where(is_active: true) }

    scope :default_currency, -> { find_by(code: "XOF", is_active: true) }

    def self.ransackable_attributes(auth_object = nil)
        [ "code", "created_at", "decimal_separator", "id", "is_active", "name", "symbol", "symbol_precedes_amount", "thousands_separator", "updated_at" ]
    end
end
