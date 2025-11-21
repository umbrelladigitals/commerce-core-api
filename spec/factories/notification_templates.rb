FactoryBot.define do
  factory :notification_template do
    sequence(:name) { |n| "template_#{n}" }
    channel { 'email' }
    subject { 'Test Subject {{customer_name}}' }
    body { 'Hello {{customer_name}}, your order {{order_id}} status: {{status}}' }
    active { true }
    
    trait :email do
      channel { 'email' }
      subject { 'Order Status Update' }
    end
    
    trait :sms do
      channel { 'sms' }
      subject { nil }
    end
    
    trait :whatsapp do
      channel { 'whatsapp' }
      subject { nil }
    end
    
    trait :inactive do
      active { false }
    end
    
    trait :order_paid do
      name { 'order_status_paid' }
      channel { 'email' }
      subject { 'Order Confirmation - {{order_number}}' }
      body { 'Thank you {{customer_name}}! Your order {{order_number}} has been confirmed.' }
    end
    
    trait :order_shipped do
      name { 'order_status_shipped' }
      channel { 'email' }
      subject { 'Order Shipped - {{order_number}}' }
      body { 'Your order {{order_number}} has been shipped. Tracking: {{tracking}}' }
    end
  end
end
