FactoryBot.define do
  factory :address do
    user { nil }
    title { "MyString" }
    name { "MyString" }
    phone { "MyString" }
    address_line1 { "MyString" }
    address_line2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    postal_code { "MyString" }
    country { "MyString" }
    address_type { 1 }
  end
end
