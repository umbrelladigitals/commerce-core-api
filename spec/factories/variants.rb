FactoryBot.define do
  factory :variant, class: 'Catalog::Variant' do
    association :product, factory: :product
    sequence(:sku) { |n| "VAR-#{n.to_s.rjust(3, '0')}" }
    price_cents { 100000 }
    currency { 'USD' }
    stock { 50 }
    options { { color: 'Black', size: 'M' } }
    
    trait :out_of_stock do
      stock { 0 }
    end
    
    trait :low_stock do
      stock { 3 }
    end
  end
end
