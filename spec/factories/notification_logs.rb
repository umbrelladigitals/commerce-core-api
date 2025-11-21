FactoryBot.define do
  factory :notification_log do
    association :notification_template
    association :user
    recipient { 'test@example.com' }
    channel { 'email' }
    status { 'pending' }
    payload { {} }
    
    trait :sent do
      status { 'sent' }
      sent_at { Time.current }
    end
    
    trait :failed do
      status { 'failed' }
      error_message { 'Failed to send' }
    end
    
    trait :delivered do
      status { 'delivered' }
      sent_at { Time.current }
    end
  end
end
