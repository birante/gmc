FactoryBot.define do
  factory :rule do
    code { "MyString" }
    description { "MyText" }
    rule_type { "MyString" }
    default_value { "" }
    is_active { false }
  end
end
