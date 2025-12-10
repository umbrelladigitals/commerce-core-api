FactoryBot.define do
  factory :promotions_coupon, class: 'Promotions::Coupon' do
    code { "MyString" }
    discount_type { 1 }
    value { "9.99" }
    min_order_amount_cents { 1 }
    min_order_amount_currency { "MyString" }
    starts_at { "2025-11-27 03:53:03" }
    ends_at { "2025-11-27 03:53:03" }
    active { false }
    usage_limit { 1 }
    usage_count { 1 }
  end
end
