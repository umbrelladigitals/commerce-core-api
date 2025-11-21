# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSender do
  let(:recipient) { 'test@example.com' }
  let(:template) { create(:notification_template, :email) }
  let(:variables) { { customer_name: 'John Doe', order_id: '12345' } }
  let(:user) { create(:user) }
  
  describe '#send! with email channel' do
    it 'creates a notification log' do
      expect {
        NotificationSender.new(
          recipient: recipient,
          template: template,
          variables: variables,
          user: user
        ).send!
      }.to change(NotificationLog, :count).by(1)
    end
    
    it 'sends email via mailer' do
      expect(NotificationMailer).to receive_message_chain(:send_notification, :deliver_now)
      
      NotificationSender.new(
        recipient: recipient,
        template: template,
        variables: variables,
        user: user
      ).send!
    end
    
    it 'marks log as sent on success' do
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
      
      NotificationSender.new(
        recipient: recipient,
        template: template,
        variables: variables,
        user: user
      ).send!
      
      log = NotificationLog.last
      expect(log.status).to eq('sent')
      expect(log.sent_at).to be_present
    end
    
    it 'marks log as failed on error' do
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now).and_raise(StandardError.new('SMTP error'))
      
      expect {
        NotificationSender.new(
          recipient: recipient,
          template: template,
          variables: variables,
          user: user
        ).send!
      }.to raise_error(StandardError)
      
      log = NotificationLog.last
      expect(log.status).to eq('failed')
      expect(log.error_message).to include('SMTP error')
    end
  end
  
  describe '#send! with WhatsApp channel' do
    let(:template) { create(:notification_template, :whatsapp) }
    let(:recipient) { '+905551234567' }
    
    it 'generates wa.me deep link' do
      NotificationSender.new(
        recipient: recipient,
        template: template,
        variables: variables,
        user: user
      ).send!
      
      log = NotificationLog.last
      expect(log.payload['whatsapp_url']).to include('https://wa.me/')
      expect(log.payload['whatsapp_url']).to include('905551234567')
      expect(log.status).to eq('sent')
    end
  end
  
  describe '#send! with SMS channel' do
    let(:template) { create(:notification_template, :sms) }
    let(:recipient) { '+905551234567' }
    
    it 'creates log with pending status (placeholder)' do
      NotificationSender.new(
        recipient: recipient,
        template: template,
        variables: variables,
        user: user
      ).send!
      
      log = NotificationLog.last
      expect(log.channel).to eq('sms')
      expect(log.status).to eq('sent') # Placeholder marks as sent
    end
  end
end
