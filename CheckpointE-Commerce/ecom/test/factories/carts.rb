FactoryBot.define do
  factory :cart do
    association :user
    status { "active" }
  end
end
