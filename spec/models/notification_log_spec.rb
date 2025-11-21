# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationLog, type: :model do
  describe 'scopes' do
    before do
      create(:notification_log, :sent, channel: 'email')
      create(:notification_log, :failed, channel: 'sms')
      create(:notification_log, status: 'pending', channel: 'whatsapp')
      create(:notification_log, :delivered, channel: 'email')
    end
    
    it 'filters by status' do
      expect(NotificationLog.pending.count).to eq(1)
      expect(NotificationLog.sent.count).to eq(1)
      expect(NotificationLog.failed.count).to eq(1)
      expect(NotificationLog.delivered.count).to eq(1)
    end
    
    it 'filters by channel' do
      expect(NotificationLog.by_channel('email').count).to eq(2)
      expect(NotificationLog.by_channel('sms').count).to eq(1)
    end
  end
  
  describe '#mark_as_sent!' do
    let(:log) { create(:notification_log, status: 'pending') }
    
    it 'updates status to sent and sets sent_at' do
      log.mark_as_sent!
      expect(log.reload.status).to eq('sent')
      expect(log.sent_at).to be_present
    end
  end
  
  describe '#mark_as_failed!' do
    let(:log) { create(:notification_log, status: 'pending') }
    
    it 'updates status to failed and sets error_message' do
      log.mark_as_failed!('Connection timeout')
      expect(log.reload.status).to eq('failed')
      expect(log.error_message).to eq('Connection timeout')
    end
  end
  
  describe '#mark_as_delivered!' do
    let(:log) { create(:notification_log, :sent) }
    
    it 'updates status to delivered' do
      log.mark_as_delivered!
      expect(log.reload.status).to eq('delivered')
    end
  end
end
