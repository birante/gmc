FactoryBot.define do
  factory :product_category do
    sequence(:name) { |n| "Catégorie Test #{n}" }
    description { "Description de la catégorie de test" }
    is_active { true }
  end
end
