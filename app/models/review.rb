# frozen_string_literal: true

class Review < ApplicationRecord
  belongs_to :product
  belongs_to :user, optional: true
  
  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true, length: { minimum: 10, maximum: 1000 }
  validate :user_or_guest_email_present
  validates :guest_email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { guest_email.present? }
  
  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  
  # Methods
  def approve!
    update!(approved: true)
  end
  
  def reject!
    update!(approved: false)
  end
  
  def reviewer_name
    user&.name || guest_email&.split('@')&.first || 'Guest'
  end
  
  def guest_review?
    user_id.nil?
  end
  
  private
  
  def user_or_guest_email_present
    if user_id.blank? && guest_email.blank?
      errors.add(:base, 'Either user or guest_email must be present')
    end
  end
end
