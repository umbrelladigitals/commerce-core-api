FactoryBot.define do
  factory :notification do
    recipient { nil }
    actor { nil }
    notifiable { nil }
    action { "MyString" }
    read_at { "2025-12-30 20:39:56" }
    data { "" }
  end
end
