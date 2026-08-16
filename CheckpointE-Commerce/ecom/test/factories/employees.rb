FactoryBot.define do
  factory :employee do
    association :vendor
    sequence(:email) { |n| "employee#{n}@example.com" }
    password { "password123" }
    first_name { "Test" }
    last_name { "Collaborator" }
    country_code { "221" }
    phone_number { "771234567" }
    role { Employee::ROLES[:cashier] }
    status { "active" }
  end
end
