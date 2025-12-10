# frozen_string_literal: true

module Orders
  # Sipariş fiyat hesaplama servisi
  # B2B dealer indirimleri ve bakiye yönetimi desteği ile
  #
  # Kullanım:
  #   calculator = Orders::OrderPriceCalculator.new(order)
  #   calculator.calculate!
  #
  # Hesaplamalar:
  # - Ara toplam (subtotal): Tüm order_lines toplamı (dealer indirimleri dahil)
  # - Kargo (shipping): 200 TL üzeri ücretsiz
  # - Vergi (tax): (Ara toplam + Kargo) × 0.18
  # - Genel toplam (total): Ara toplam + Kargo + Vergi
  #
  # B2B Özellikleri:
  # - Dealer'lar için otomatik indirim uygulaması
  # - Dealer bakiyesinden ödeme desteği
  class OrderPriceCalculator
    attr_reader :order, :user
    
    # B2B - Dealer'lar için ücretsiz kargo limiti daha düşük
    DEALER_FREE_SHIPPING_THRESHOLD = 10000 # 100.00 TL
    
    # Dinamik ayarları al
    def self.tax_rate
      Setting.tax_rate
    end
    
    def self.free_shipping_threshold
      (Setting.free_shipping_threshold * 100).to_i # Convert TL to cents
    end
    
    def self.shipping_fee
      (Setting.default_shipping_cost * 100).to_i # Convert TL to cents
    end
    
    def initialize(order)
      @order = order
      @user = order.user
    end
    
    # Kullanıcı dealer mı?
    def dealer?
      user&.dealer?
    end
    
    # Tüm hesaplamaları yap ve siparişi güncelle
    def calculate!
      order.transaction do
        # Ara toplamı hesapla
        subtotal = calculate_subtotal
        
        # Dealer indirimini hesapla
        dealer_discount = calculate_dealer_discount_total

        # Kupon indirimini hesapla (Dealer indiriminden sonraki tutar üzerinden mi? Yoksa subtotal üzerinden mi? Genelde subtotal)
        # Ancak kümülatif indirim olmaması için dealer indiriminden kalana uygulamak daha güvenli olabilir.
        # Şimdilik subtotal üzerinden uygulayalım ama toplam indirim subtotal'i geçemez.
        coupon_discount = calculate_coupon_discount(subtotal)
        
        total_discount = dealer_discount + coupon_discount
        
        # İndirim toplam tutarı geçemez
        total_discount = subtotal if total_discount > subtotal

        # Kargo ücretini hesapla (indirimden sonraki tutara göre)
        shipping = calculate_shipping(subtotal - total_discount)
        
        # Vergiyi hesapla (ara toplam - indirim + kargo üzerinden)
        tax = calculate_tax(subtotal - total_discount + shipping)
        
        # Genel toplamı hesapla
        total = subtotal - total_discount + shipping + tax
        
        # Siparişi güncelle
        order.update_columns(
          subtotal_cents: subtotal,
          discount_cents: total_discount,
          shipping_cents: shipping,
          tax_cents: tax,
          total_cents: total,
          updated_at: Time.current
        )
      end
      
      order.reload
    end
    
    # Sadece hesapla, kaydetme (önizleme için)
    def preview
      subtotal = calculate_subtotal
      dealer_discount = calculate_dealer_discount_total
      coupon_discount = calculate_coupon_discount(subtotal)
      total_discount = dealer_discount + coupon_discount
      total_discount = subtotal if total_discount > subtotal

      shipping = calculate_shipping(subtotal - total_discount)
      tax = calculate_tax(subtotal + shipping - total_discount)
      total = subtotal + shipping - total_discount + tax
      
      result = {
        subtotal_cents: subtotal,
        subtotal: Money.new(subtotal, order.currency).format,
        shipping_cents: shipping,
        shipping: Money.new(shipping, order.currency).format,
        tax_cents: tax,
        tax: Money.new(tax, order.currency).format,
        total_cents: total,
        total: Money.new(total, order.currency).format,
        discount_cents: total_discount,
        discount: Money.new(total_discount, order.currency).format,
        currency: order.currency,
        items_count: order.order_lines.sum(:quantity),
        free_shipping: shipping.zero?
      }
      
      # B2B bilgileri ekle
      if dealer?
        result.merge!(
          is_dealer: true,
          dealer_discount_cents: dealer_discount,
          dealer_discount: Money.new(dealer_discount, order.currency).format,
          dealer_balance: user.dealer_balance&.summary
        )
      end

      # Kupon bilgisi ekle
      if order.coupon
        result.merge!(
          coupon_code: order.coupon.code,
          coupon_discount_cents: coupon_discount,
          coupon_discount: Money.new(coupon_discount, order.currency).format
        )
      end
      
      result
    end
    
    private
    
    # Ara toplam: Tüm order_lines'ların toplamı
    def calculate_subtotal
      order.order_lines.sum(:total_cents)
    end
    
    # Kargo ücreti hesapla
    # Normal: 200 TL ve üzeri ücretsiz
    # Dealer: 100 TL ve üzeri ücretsiz (B2B avantajı)
    def calculate_shipping(subtotal)
      threshold = dealer? ? DEALER_FREE_SHIPPING_THRESHOLD : self.class.free_shipping_threshold
      return 0 if subtotal >= threshold
      self.class.shipping_fee
    end
    
    # Vergi hesapla (KDV - dinamik oran)
    # Ara toplam + kargo - dealer indirimleri üzerinden hesaplanır
    def calculate_tax(taxable_amount)
      (taxable_amount * self.class.tax_rate).round
    end
    
    # Dealer indirimi toplamını hesapla
    # Her order_line için dealer indirimini uygula
    def calculate_dealer_discount_total
      return 0 unless dealer?
      
      total_discount = 0
      
      order.order_lines.each do |line|
        discount = user.discount_for(line.product)
        next unless discount
        
        # İndirim tutarını hesapla
        discount_amount = discount.discount_amount(line.total_cents)
        total_discount += discount_amount
      end
      
      total_discount
    end

    # Kupon indirimini hesapla
    def calculate_coupon_discount(amount_cents)
      return 0 unless order.coupon
      return 0 unless order.coupon.applicable?(order)
      
      order.coupon.calculate_discount(amount_cents)
    end
  end
end
