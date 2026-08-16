FactoryBot.define do
  factory :delivery_slot do
    start_time { "09:00" }
    end_time { "12:00" }
    is_active { true }
  end
end
