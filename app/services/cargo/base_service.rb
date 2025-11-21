# frozen_string_literal: true

module Cargo
  # Base kargo servisi
  # Tüm kargo firmaları bu sınıftan türetilir (Adapter Pattern)
  class BaseService
    attr_reader :shipment
    
    def initialize(shipment)
      @shipment = shipment
    end
    
    # Kargo oluştur (her firmada override edilir)
    # @return [Hash] { success: true/false, tracking_number: string, error: string }
    def create_shipment
      raise NotImplementedError, "#{self.class} must implement #create_shipment"
    end
    
    # Kargo durumunu sorgula
    # @return [Hash] { status: string, location: string, estimated_delivery: date }
    def track_shipment
      raise NotImplementedError, "#{self.class} must implement #track_shipment"
    end
    
    # Kargo iptal et
    # @return [Boolean]
    def cancel_shipment
      raise NotImplementedError, "#{self.class} must implement #cancel_shipment"
    end
    
    # Kargo firmasını döndür
    def self.carrier_name
      raise NotImplementedError, "#{self.class} must implement .carrier_name"
    end
    
    protected
    
    # Sipariş bilgilerini hazırla
    def prepare_order_data
      {
        order_number: shipment.order.order_number,
        customer_name: shipment.order.user.name,
        customer_email: shipment.order.user.email,
        customer_phone: shipment.order.user.phone || '0000000000',
        items: shipment.order.order_lines.map { |line|
          {
            title: line.product_title,
            quantity: line.quantity,
            price: line.unit_price.to_f
          }
        },
        total: shipment.order.total.to_f
      }
    end
    
    # Mock tracking number oluştur
    def generate_mock_tracking_number
      carrier_prefix = self.class.carrier_name[0..2].upcase
      timestamp = Time.now.to_i
      random = SecureRandom.hex(4).upcase
      "#{carrier_prefix}#{timestamp}#{random}"
    end
    
    # Mock teslimat tarihi hesapla
    def calculate_estimated_delivery(days = 3)
      Date.today + days.days
    end
  end
end
