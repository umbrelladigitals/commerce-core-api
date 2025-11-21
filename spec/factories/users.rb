FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :customer }
    
    trait :admin do
      role { :admin }
    end
    
    trait :dealer do
      role { :dealer }
    end
    
    trait :manufacturer do
      role { :manufacturer }
    end
    
    trait :marketer do
      role { :marketer }
    end
  end
end
