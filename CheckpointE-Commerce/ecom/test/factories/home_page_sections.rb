FactoryBot.define do
  factory :home_page_section do
    section_type { "MyString" }
    title { "MyString" }
    description { "MyText" }
    is_active { false }
    position { 1 }
  end
end
