FactoryBot.define do
  factory :order_status_log do
    association :order, factory: :order
    association :user
    from_status { 'pending' }
    to_status { 'in_production' }
    changed_at { Time.current }
  end
end
