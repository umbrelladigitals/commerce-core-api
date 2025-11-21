FactoryBot.define do
  factory :product_option, class: 'Catalog::ProductOption' do
    association :product, factory: :product
    sequence(:name) { |n| "Option #{n}" }
    option_type { 'select' }
    required { false }
    position { 0 }
    
    trait :required do
      required { true }
    end
    
    trait :radio do
      option_type { 'radio' }
    end
    
    trait :checkbox do
      option_type { 'checkbox' }
    end
    
    trait :color do
      option_type { 'color' }
    end
  end
end
