# frozen_string_literal: true

module B2b
  # Dealer'lara özel ürün indirimleri
  # Her dealer için farklı ürünlerde farklı indirim oranları tanımlanabilir
  #
  # Örnek:
  #   dealer = User.find_by(role: :dealer)
  #   product = Catalog::Product.first
  #   discount = B2b::DealerDiscount.create!(
  #     dealer: dealer,
  #     product: product,
  #     discount_percent: 15.5
  #   )
  class DealerDiscount < ApplicationRecord
    self.table_name = 'dealer_discounts'
    
    # İlişkiler
    belongs_to :dealer, class_name: 'User', foreign_key: :dealer_id
    belongs_to :product, class_name: 'Catalog::Product'
    
    # Validasyonlar
    validates :dealer, presence: true
    validates :product, presence: true
    validates :discount_percent, presence: true, 
              numericality: { 
                greater_than_or_equal_to: 0, 
                less_than_or_equal_to: 100 
              }
    validates :dealer_id, uniqueness: { 
      scope: :product_id, 
      message: 'already has a discount for this product' 
    }
    validate :dealer_must_be_dealer_role
    
    # Scope'lar
    scope :active, -> { where(active: true) }
    scope :for_dealer, ->(dealer_id) { where(dealer_id: dealer_id) }
    scope :for_product, ->(product_id) { where(product_id: product_id) }
    
    # İndirimli fiyatı hesapla
    # @param original_price_cents [Integer] Orijinal fiyat (cents cinsinden)
    # @return [Integer] İndirimli fiyat (cents cinsinden)
    def calculate_discounted_price(original_price_cents)
      return original_price_cents unless active?
      
      discount_amount = (original_price_cents * discount_percent / 100.0).round
      original_price_cents - discount_amount
    end
    
    # İndirim tutarını hesapla
    # @param original_price_cents [Integer] Orijinal fiyat (cents cinsinden)
    # @return [Integer] İndirim tutarı (cents cinsinden)
    def discount_amount(original_price_cents)
      (original_price_cents * discount_percent / 100.0).round
    end
    
    # İndirim miktarını yüzde olarak formatla
    # @return [String] "%15.5" gibi
    def formatted_discount
      "#{discount_percent}%"
    end
    
    # İndirimi aktif/pasif yap
    def toggle_active!
      update!(active: !active)
    end
    
    private
    
    # Dealer'ın role'ünün dealer olduğunu kontrol et
    def dealer_must_be_dealer_role
      return if dealer.nil?
      
      unless dealer.dealer?
        errors.add(:dealer, 'must have dealer role')
      end
    end
  end
end
