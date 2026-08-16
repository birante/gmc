FactoryBot.define do
  factory :currency do
    # Use sequence to avoid duplicate XOF entries
    sequence(:code) { |n| format("CUR%04d", n) }
    symbol { "FCFA" }
    name { "Test Currency" }
    thousands_separator { " " }
    decimal_separator { "," }
    symbol_precedes_amount { false }
    is_active { true }

    # Trait for XOF currency (will use existing fixture if available)
    trait :xof do
      code { "XOF" }
      symbol { "FCFA" }
      name { "West African CFA franc" }

      initialize_with do
        Currency.find_or_create_by(code: "XOF") do |currency|
          currency.symbol = "FCFA"
          currency.name = "West African CFA franc"
          currency.thousands_separator = " "
          currency.decimal_separator = ","
          currency.symbol_precedes_amount = false
          currency.is_active = true
        end
      end
    end

    # Trait for USD
    trait :usd do
      code { "USD" }
      symbol { "$" }
      name { "US Dollar" }
      thousands_separator { "," }
      decimal_separator { "." }
      symbol_precedes_amount { true }

      initialize_with do
        Currency.find_or_create_by(code: "USD") do |currency|
          currency.symbol = "$"
          currency.name = "US Dollar"
          currency.thousands_separator = ","
          currency.decimal_separator = "."
          currency.symbol_precedes_amount = true
          currency.is_active = true
        end
      end
    end
  end
end
