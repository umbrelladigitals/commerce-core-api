FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-10-10 00:47:39" }
  end
end
