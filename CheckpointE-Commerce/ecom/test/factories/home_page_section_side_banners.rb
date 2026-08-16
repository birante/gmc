FactoryBot.define do
  factory :home_page_section_side_banner do
    home_page_section { nil }
    title { "MyString" }
    subtitle { "MyString" }
    description { "MyText" }
    cta_text { "MyString" }
    cta_link { "MyString" }
    bg_color { "MyString" }
    text_color { "MyString" }
    position { 1 }
    is_active { false }
  end
end
