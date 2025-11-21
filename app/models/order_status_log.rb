# frozen_string_literal: true

class OrderStatusLog < ApplicationRecord
  # Associations
  belongs_to :order, class_name: 'Orders::Order'
  belongs_to :user
  
  # Validations
  validates :to_status, presence: true
  validates :changed_at, presence: true
  
  # Scopes
  scope :recent, -> { order(changed_at: :desc) }
  scope :for_order, ->(order_id) { where(order_id: order_id) }
end
