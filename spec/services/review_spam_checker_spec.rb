# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewSpamChecker do
  let(:product) { create(:product, 'Catalog::Product') }
  let(:user) { create(:user) }
  
  describe '#allowed?' do
    context 'when no recent review exists' do
      it 'allows review submission' do
        checker = ReviewSpamChecker.new(
          product_id: product.id,
          user: user,
          reviewer_ip: '192.168.1.1'
        )
        
        expect(checker.allowed?).to be true
      end
    end
    
    context 'when user submitted review recently' do
      before do
        create(:review, product: product, user: user, created_at: 1.hour.ago)
      end
      
      it 'prevents review submission' do
        checker = ReviewSpamChecker.new(
          product_id: product.id,
          user: user,
          reviewer_ip: '192.168.1.1'
        )
        
        expect(checker.allowed?).to be false
      end
    end
    
    context 'when 24 hours passed since last review' do
      before do
        create(:review, product: product, user: user, created_at: 25.hours.ago)
      end
      
      it 'allows review submission' do
        checker = ReviewSpamChecker.new(
          product_id: product.id,
          user: user,
          reviewer_ip: '192.168.1.1'
        )
        
        expect(checker.allowed?).to be true
      end
    end
    
    context 'when guest submitted from same IP' do
      before do
        create(:review, :guest, 
               product: product, 
               reviewer_ip: '192.168.1.1',
               created_at: 1.hour.ago)
      end
      
      it 'prevents review submission' do
        checker = ReviewSpamChecker.new(
          product_id: product.id,
          guest_email: 'new@example.com',
          reviewer_ip: '192.168.1.1'
        )
        
        expect(checker.allowed?).to be false
      end
    end
    
    context 'when guest submitted with same email' do
      before do
        create(:review, :guest,
               product: product,
               guest_email: 'test@example.com',
               created_at: 1.hour.ago)
      end
      
      it 'prevents review submission' do
        checker = ReviewSpamChecker.new(
          product_id: product.id,
          guest_email: 'test@example.com',
          reviewer_ip: '192.168.2.1'
        )
        
        expect(checker.allowed?).to be false
      end
    end
    
    context 'when review is for different product' do
      let(:other_product) { create(:product, 'Catalog::Product') }
      
      before do
        create(:review, product: other_product, user: user, created_at: 1.hour.ago)
      end
      
      it 'allows review submission' do
        checker = ReviewSpamChecker.new(
          product_id: product.id,
          user: user,
          reviewer_ip: '192.168.1.1'
        )
        
        expect(checker.allowed?).to be true
      end
    end
  end
  
  describe '#error_message' do
    it 'returns nil when allowed' do
      checker = ReviewSpamChecker.new(
        product_id: product.id,
        user: user,
        reviewer_ip: '192.168.1.1'
      )
      
      expect(checker.error_message).to be_nil
    end
    
    it 'returns error message when not allowed' do
      create(:review, product: product, user: user, created_at: 1.hour.ago)
      
      checker = ReviewSpamChecker.new(
        product_id: product.id,
        user: user,
        reviewer_ip: '192.168.1.1'
      )
      
      expect(checker.error_message).to include('24 hours')
    end
  end
end
