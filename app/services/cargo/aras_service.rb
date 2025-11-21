# frozen_string_literal: true

module Cargo
  # Aras Kargo servisi (Mock)
  # Gerçek API: https://api.araskargo.com.tr/
  class ArasService < BaseService
    def self.carrier_name
      'ARAS'
    end
    
    # Aras Kargo oluştur (Mock)
    def create_shipment
      order_data = prepare_order_data
      
      Rails.logger.info "Aras Kargo oluşturuluyor: #{order_data.inspect}"
      
      tracking_number = generate_mock_tracking_number
      
      {
        success: true,
        tracking_number: tracking_number,
        estimated_delivery: calculate_estimated_delivery(2), # Aras 2 gün
        message: 'Aras Kargo başarıyla oluşturuldu',
        api_response: mock_api_response(tracking_number)
      }
    rescue StandardError => e
      {
        success: false,
        error: e.message
      }
    end
    
    # Aras Kargo takip (Mock)
    def track_shipment
      Rails.logger.info "Aras Kargo takip ediliyor: #{shipment.tracking_number}"
      
      {
        success: true,
        tracking_number: shipment.tracking_number,
        status: mock_current_status,
        location: 'Ankara Transfer Merkezi',
        last_update: Time.current,
        estimated_delivery: shipment.estimated_delivery,
        history: mock_tracking_history
      }
    end
    
    # Aras Kargo iptal (Mock)
    def cancel_shipment
      Rails.logger.info "Aras Kargo iptal ediliyor: #{shipment.tracking_number}"
      true
    rescue StandardError => e
      Rails.logger.error "Aras Kargo iptal hatası: #{e.message}"
      false
    end
    
    # Gerçek Aras API entegrasyonu için placeholder
    def self.create_via_api(order, credentials)
      # TODO: Gerçek Aras API entegrasyonu
      # require 'savon' # SOAP client
      # client = Savon.client(wsdl: 'https://api.araskargo.com.tr/service.asmx?wsdl')
      # response = client.call(:create_shipment, message: {
      #   username: credentials[:username],
      #   password: credentials[:password],
      #   ...
      # })
    end
    
    private
    
    def mock_api_response(tracking_number)
      {
        shipment_id: tracking_number,
        status_code: '100',
        status_message: 'Gönderi oluşturuldu',
        created_at: Time.current.iso8601
      }
    end
    
    def mock_current_status
      case shipment.status
      when 'preparing'
        'Gönderi hazırlanıyor'
      when 'in_transit'
        'Aktarma merkezinde'
      when 'out_for_delivery'
        'Kurye dağıtımda'
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
          status: 'Gönderi alındı',
          location: 'İstanbul Şişli Şubesi'
        },
        {
          date: 1.day.ago,
          status: 'Aktarma merkezinde',
          location: 'Ankara Transfer Merkezi'
        },
        {
          date: Time.current,
          status: mock_current_status,
          location: 'Ankara Transfer Merkezi'
        }
      ]
    end
  end
end
