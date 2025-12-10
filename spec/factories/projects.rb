FactoryBot.define do
  factory :project do
    name { "MyString" }
    description { "MyText" }
    status { 1 }
    user { nil }
    start_date { "2025-12-10 02:15:00" }
    due_date { "2025-12-10 02:15:00" }
  end
end
