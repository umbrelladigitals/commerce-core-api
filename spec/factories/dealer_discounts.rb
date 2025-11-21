FactoryBot.define do
  factory :dealer_discount, class: 'B2b::DealerDiscount' do
    association :dealer, factory: :user, role: :dealer
    association :product, factory: :product
    discount_percent { 10.0 }
    active { true }
    
    trait :inactive do
      active { false }
    end
    
    trait :high_discount do
      discount_percent { 25.0 }
    end
  end
end
