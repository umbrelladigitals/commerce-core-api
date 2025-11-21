# frozen_string_literal: true

module Cargo
  # PTT Kargo servisi (Mock)
  # Gerçek API: https://gonderitakip.ptt.gov.tr/
  class PttService < BaseService
    def self.carrier_name
      'PTT'
    end
    
    # PTT Kargo oluştur (Mock)
    def create_shipment
      order_data = prepare_order_data
      
      # Mock: Gerçek API'de burada PTT API'sine istek atılır
      Rails.logger.info "PTT Kargo oluşturuluyor: #{order_data.inspect}"
      
      # Mock tracking number
      tracking_number = generate_mock_tracking_number
      
      # Mock başarılı response
      {
        success: true,
        tracking_number: tracking_number,
        estimated_delivery: calculate_estimated_delivery(3), # PTT 3 gün
        message: 'PTT Kargo başarıyla oluşturuldu',
        api_response: mock_api_response(tracking_number)
      }
    rescue StandardError => e
      {
        success: false,
        error: e.message
      }
    end
    
    # PTT Kargo takip (Mock)
    def track_shipment
      # Mock: Gerçek API'de PTT tracking API'sine istek atılır
      Rails.logger.info "PTT Kargo takip ediliyor: #{shipment.tracking_number}"
      
      # Mock tracking bilgileri
      {
        success: true,
        tracking_number: shipment.tracking_number,
        status: mock_current_status,
        location: 'İstanbul Anadolu Dağıtım Merkezi',
        last_update: Time.current,
        estimated_delivery: shipment.estimated_delivery,
        history: mock_tracking_history
      }
    end
    
    # PTT Kargo iptal (Mock)
    def cancel_shipment
      # Mock: Gerçek API'de PTT cancel API'sine istek atılır
      Rails.logger.info "PTT Kargo iptal ediliyor: #{shipment.tracking_number}"
      
      # Mock başarılı iptal
      true
    rescue StandardError => e
      Rails.logger.error "PTT Kargo iptal hatası: #{e.message}"
      false
    end
    
    # Gerçek PTT API entegrasyonu için placeholder
    def self.create_via_api(order, credentials)
      # TODO: Gerçek PTT API entegrasyonu
      # require 'net/http'
      # uri = URI('https://pttapi.example.com/shipment/create')
      # response = Net::HTTP.post_form(uri, {
      #   api_key: credentials[:api_key],
      #   sender: {...},
      #   receiver: {...},
      #   package: {...}
      # })
      # JSON.parse(response.body)
    end
    
    private
    
    def mock_api_response(tracking_number)
      {
        barcode: tracking_number,
        status: 'CREATED',
        create_date: Time.current.iso8601
      }
    end
    
    def mock_current_status
      case shipment.status
      when 'preparing'
        'Kargo hazırlanıyor'
      when 'in_transit'
        'Transfer merkezinde'
      when 'out_for_delivery'
        'Dağıtımda'
      when 'delivered'
        'Teslim edildi'
      else
        'Bilinmeyen durum'
      end
    end
    
    def mock_tracking_history
      [
        {
          date: 2.days.ago,
          status: 'Kargo alındı',
          location: 'İstanbul Merkez Şube'
        },
        {
          date: 1.day.ago,
          status: 'Transfer merkezinde',
          location: 'İstanbul Anadolu Dağıtım Merkezi'
        },
        {
          date: Time.current,
          status: mock_current_status,
          location: 'İstanbul Anadolu Dağıtım Merkezi'
        }
      ]
    end
  end
end
