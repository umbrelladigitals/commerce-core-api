# frozen_string_literal: true

module Cargo
  # Yurtiçi Kargo servisi (Mock)
  # Gerçek API: https://api.yurticikargo.com/
  class YurticiService < BaseService
    def self.carrier_name
      'YURTICI'
    end
    
    # Yurtiçi Kargo oluştur (Mock)
    def create_shipment
      order_data = prepare_order_data
      
      Rails.logger.info "Yurtiçi Kargo oluşturuluyor: #{order_data.inspect}"
      
      tracking_number = generate_mock_tracking_number
      
      {
        success: true,
        tracking_number: tracking_number,
        estimated_delivery: calculate_estimated_delivery(2), # Yurtiçi 2 gün
        message: 'Yurtiçi Kargo başarıyla oluşturuldu',
        api_response: mock_api_response(tracking_number)
      }
    rescue StandardError => e
      {
        success: false,
        error: e.message
      }
    end
    
    # Yurtiçi Kargo takip (Mock)
    def track_shipment
      Rails.logger.info "Yurtiçi Kargo takip ediliyor: #{shipment.tracking_number}"
      
      {
        success: true,
        tracking_number: shipment.tracking_number,
        status: mock_current_status,
        location: 'İzmir Bölge Müdürlüğü',
        last_update: Time.current,
        estimated_delivery: shipment.estimated_delivery,
        history: mock_tracking_history
      }
    end
    
    # Yurtiçi Kargo iptal (Mock)
    def cancel_shipment
      Rails.logger.info "Yurtiçi Kargo iptal ediliyor: #{shipment.tracking_number}"
      true
    rescue StandardError => e
      Rails.logger.error "Yurtiçi Kargo iptal hatası: #{e.message}"
      false
    end
    
    # Gerçek Yurtiçi API entegrasyonu için placeholder
    def self.create_via_api(order, credentials)
      # TODO: Gerçek Yurtiçi API entegrasyonu
      # require 'net/http'
      # uri = URI('https://api.yurticikargo.com/api/ShipmentIntegration/CreateShipment')
      # http = Net::HTTP.new(uri.host, uri.port)
      # http.use_ssl = true
      # request = Net::HTTP::Post.new(uri)
      # request['Authorization'] = "Bearer #{credentials[:api_token]}"
      # request.body = shipment_data.to_json
      # response = http.request(request)
    end
    
    private
    
    def mock_api_response(tracking_number)
      {
        cargo_key: tracking_number,
        result: 'SUCCESS',
        message: 'Kargo kaydı oluşturuldu',
        timestamp: Time.current.iso8601
      }
    end
    
    def mock_current_status
      case shipment.status
      when 'preparing'
        'Kargo kaydı oluşturuldu'
      when 'in_transit'
        'Bölge müdürlüğünde'
      when 'out_for_delivery'
        'Dağıtıma çıktı'
      when 'delivered'
        'Teslim edildi'
      else
        'Durum bilinmiyor'
      end
    end
    
    def mock_tracking_history
      [
        {
          date: 2.days.ago,
          status: 'Kargo alındı',
          location: 'İzmir Karşıyaka Şubesi'
        },
        {
          date: 1.day.ago,
          status: 'Bölge müdürlüğüne ulaştı',
          location: 'İzmir Bölge Müdürlüğü'
        },
        {
          date: Time.current,
          status: mock_current_status,
          location: 'İzmir Bölge Müdürlüğü'
        }
      ]
    end
  end
end
