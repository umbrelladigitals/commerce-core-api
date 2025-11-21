FactoryBot.define do
  factory :category, class: 'Catalog::Category' do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    
    trait :with_parent do
      association :parent, factory: :category
    end
    
    trait :with_children do
      after(:create) do |category|
        create_list(:category, 3, parent: category)
      end
    end
  end
end
