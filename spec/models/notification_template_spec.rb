# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationTemplate, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      template = build(:notification_template, :email)
      expect(template).to be_valid
    end
    
    it 'requires name' do
      template = build(:notification_template, name: nil)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("can't be blank")
    end
    
    it 'requires channel' do
      template = build(:notification_template, channel: nil)
      expect(template).not_to be_valid
      expect(template.errors[:channel]).to include("can't be blank")
    end
    
    it 'requires body' do
      template = build(:notification_template, body: nil)
      expect(template).not_to be_valid
      expect(template.errors[:body]).to include("can't be blank")
    end
    
    it 'validates channel inclusion' do
      template = build(:notification_template, channel: 'invalid')
      expect(template).not_to be_valid
      expect(template.errors[:channel]).to include('is not included in the list')
    end
    
    context 'when channel is email' do
      it 'requires subject' do
        template = build(:notification_template, :email, subject: nil)
        expect(template).not_to be_valid
        expect(template.errors[:subject]).to include("can't be blank")
      end
      
      it 'validates name uniqueness scoped to channel' do
        create(:notification_template, :email, name: 'test_template')
        duplicate = build(:notification_template, :email, name: 'test_template')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include('has already been taken')
      end
      
      it 'allows same name for different channels' do
        create(:notification_template, :email, name: 'test_template')
        sms_template = build(:notification_template, :sms, name: 'test_template')
        expect(sms_template).to be_valid
      end
    end
    
    context 'when channel is sms' do
      it 'does not require subject' do
        template = build(:notification_template, :sms, subject: nil)
        expect(template).to be_valid
      end
    end
  end
  
  describe 'scopes' do
    before do
      create(:notification_template, :email, active: true)
      create(:notification_template, :sms, active: false)
      create(:notification_template, :whatsapp, active: true)
    end
    
    it 'returns active templates' do
      expect(NotificationTemplate.active.count).to eq(2)
    end
    
    it 'filters by channel' do
      expect(NotificationTemplate.by_channel('email').count).to eq(1)
      expect(NotificationTemplate.by_channel('whatsapp').count).to eq(1)
    end
  end
  
  describe '#render_body' do
    let(:template) do
      create(:notification_template, body: 'Hello {{customer_name}}, your order {{order_id}} is ready!')
    end
    
    it 'replaces placeholders with variables' do
      result = template.render_body(customer_name: 'John Doe', order_id: '12345')
      expect(result).to eq('Hello John Doe, your order 12345 is ready!')
    end
    
    it 'leaves unreplaced placeholders' do
      result = template.render_body(customer_name: 'John Doe')
      expect(result).to eq('Hello John Doe, your order {{order_id}} is ready!')
    end
  end
  
  describe '#render_subject' do
    let(:template) do
      create(:notification_template, :email, subject: 'Order {{order_id}} Update')
    end
    
    it 'replaces placeholders in subject' do
      result = template.render_subject(order_id: '12345')
      expect(result).to eq('Order 12345 Update')
    end
  end
  
  describe 'channel helpers' do
    it 'returns true for email?' do
      template = create(:notification_template, :email)
      expect(template.email?).to be true
      expect(template.sms?).to be false
    end
    
    it 'returns true for sms?' do
      template = create(:notification_template, :sms)
      expect(template.sms?).to be true
      expect(template.email?).to be false
    end
    
    it 'returns true for whatsapp?' do
      template = create(:notification_template, :whatsapp)
      expect(template.whatsapp?).to be true
      expect(template.email?).to be false
    end
  end
end
