FactoryBot.define do
  factory :slider do
    title { "MyString" }
    subtitle { "MyText" }
    button_text { "MyString" }
    button_link { "MyString" }
    image_url { "MyString" }
    display_order { 1 }
    active { false }
  end
end
