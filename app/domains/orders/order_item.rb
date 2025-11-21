# frozen_string_literal: true

module Orders
  class OrderItem < ApplicationRecord
    self.table_name = 'order_items'
    
    belongs_to :order, class_name: 'Orders::Order'
    belongs_to :product, class_name: 'Catalog::Product'
    
    monetize :price_cents, as: :price
    
    validates :quantity, presence: true, numericality: { greater_than: 0 }
    validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  end
end
