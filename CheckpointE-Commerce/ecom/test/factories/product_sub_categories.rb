FactoryBot.define do
  factory :product_sub_category do
    association :product_category

    sequence(:name) { |n| "Sous-catégorie Test #{n}" }
    description { "Description de la sous-catégorie de test" }
    is_active { true }
  end
end
