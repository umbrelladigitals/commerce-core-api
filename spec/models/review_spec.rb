# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      review = build(:review)
      expect(review).to be_valid
    end
    
    it 'validates rating is between 1 and 5' do
      review = build(:review, rating: 0)
      expect(review).not_to be_valid
      
      review.rating = 6
      expect(review).not_to be_valid
      
      (1..5).each do |rating|
        review.rating = rating
        expect(review).to be_valid
      end
    end
    
    it 'validates comment minimum length' do
      review = build(:review, comment: 'Short')
      expect(review).not_to be_valid
    end
  end
  
  describe 'scopes' do
    before do
      create(:review, :approved, rating: 5)
      create(:review, :pending, rating: 4)
      create(:review, :approved, rating: 3)
    end
    
    it 'filters approved reviews' do
      expect(Review.approved.count).to eq(2)
    end
    
    it 'filters pending reviews' do
      expect(Review.pending.count).to eq(1)
    end
  end
  
  describe '#approve!' do
    it 'sets approved to true' do
      review = create(:review, :pending)
      review.approve!
      expect(review.reload.approved).to be true
    end
  end
  
  describe '#reviewer_name' do
    it 'returns user name when user exists' do
      user = create(:user, name: 'John Doe')
      review = create(:review, user: user)
      expect(review.reviewer_name).to eq('John Doe')
    end
    
    it 'returns guest email username when guest' do
      review = create(:review, :guest, guest_email: 'test@example.com')
      expect(review.reviewer_name).to eq('test')
    end
  end
end
