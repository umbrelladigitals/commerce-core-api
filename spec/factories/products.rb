FactoryBot.define do
  factory :product, class: 'Catalog::Product' do
    sequence(:title) { |n| "Product #{n}" }
    sequence(:sku) { |n| "PROD-#{n.to_s.rjust(3, '0')}" }
    description { "Sample product description" }
    price_cents { 100000 }
    currency { 'USD' }
    active { true }
    association :category, factory: :category
    
    trait :inactive do
      active { false }
    end
    
    trait :with_variants do
      after(:create) do |product|
        create_list(:variant, 3, product: product)
      end
    end
    
    trait :with_options do
      after(:create) do |product|
        create_list(:product_option, 2, product: product)
      end
    end
  end
end
