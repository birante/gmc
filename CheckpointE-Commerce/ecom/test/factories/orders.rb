FactoryBot.define do
  factory :order do
    association :user
    association :delivery_zone
    association :delivery_slot
    association :currency
    status { "pending" }
    total_amount { 5000.00 }
    delivery_fee { 500.00 }
    final_amount { 5500.00 }
    delivery_address { "123 Rue de la République, Dakar" }
    notes { "Appeler avant de livrer" }
  end
end
