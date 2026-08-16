FactoryBot.define do
  factory :subscription do
    association :shop
    association :plan
    status { "active" }
    started_at { 1.month.ago }
    ends_at { 11.months.from_now }
  end
end
