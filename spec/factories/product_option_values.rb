FactoryBot.define do
  factory :product_option_value, class: 'Catalog::ProductOptionValue' do
    association :product_option, factory: :product_option
    sequence(:name) { |n| "Value #{n}" }
    price_cents { 1000 }
    price_mode { 'flat' }
    position { 0 }
    meta { {} }
    
    trait :flat do
      price_mode { 'flat' }
    end
    
    trait :per_unit do
      price_mode { 'per_unit' }
    end
    
    trait :free do
      price_cents { 0 }
    end
  end
end
