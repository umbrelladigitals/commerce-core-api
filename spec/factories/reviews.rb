# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    product { nil }  # Will be set explicitly in tests
    user { nil }     # Will be set explicitly in tests
    rating { rand(1..5) }
    comment { 'This is a great product! I really enjoyed using it and would recommend to others.' }
    approved { false }
    reviewer_ip { '192.168.1.1' }
    guest_email { 'guest@example.com' }
    
    trait :approved do
      approved { true }
    end
    
    trait :pending do
      approved { false }
    end
    
    trait :guest do
      user { nil }
      guest_email { 'guest@example.com' }
    end
    
    trait :with_user do
      association :user
      guest_email { nil }
    end
    
    trait :five_stars do
      rating { 5 }
      comment { 'Excellent product! Highly recommended.' }
    end
    
    trait :one_star do
      rating { 1 }
      comment { 'Very disappointed with this product.' }
    end
  end
end
