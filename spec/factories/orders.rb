FactoryBot.define do
  factory :order, class: 'Orders::Order' do
    association :user
    status { :cart }
    production_status { 'pending' }
    total_cents { 100000 }
    subtotal_cents { 85000 }
    tax_cents { 15000 }
    shipping_cents { 0 }
    
    trait :paid do
      status { :paid }
      paid_at { Time.current }
    end
    
    trait :shipped do
      status { :shipped }
      production_status { 'shipped' }
      shipped_at { Time.current }
    end
    
    trait :cancelled do
      status { :cancelled }
      cancelled_at { Time.current }
    end
    
    trait :in_production do
      production_status { 'in_production' }
    end
    
    trait :ready do
      production_status { 'ready' }
    end
  end
end
