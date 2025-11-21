# frozen_string_literal: true

module Cargo
  # Kargo servis factory
  # Adapter pattern ile doğru kargo servisini döndürür
  class ServiceFactory
    # Kargo firmasına göre servis döndür
    # @param carrier [String, Symbol] Kargo firması (:ptt, :aras, :yurtici)
    # @param shipment [Shipment] Gönderi kaydı
    # @return [Cargo::BaseService] İlgili kargo servisi
    def self.create(carrier, shipment)
      case carrier.to_sym
      when :ptt
        Cargo::PttService.new(shipment)
      when :aras
        Cargo::ArasService.new(shipment)
      when :yurtici
        Cargo::YurticiService.new(shipment)
      else
        raise ArgumentError, "Desteklenmeyen kargo firması: #{carrier}"
      end
    end
    
    # Kullanılabilir kargo firmaları
    def self.available_carriers
      Shipment::CARRIERS
    end
    
    # Kargo firması destekleniyor mu?
    def self.supported?(carrier)
      available_carriers.key?(carrier.to_sym)
    end
  end
end
