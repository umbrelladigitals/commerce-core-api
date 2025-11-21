# frozen_string_literal: true

module Orders
  # Sipariş checkout servisi
  # E-ticaret akışını yönetir: validasyon, fiyat hesaplama, stok kontrolü, ödeme
  #
  # Kullanım:
  #   service = Orders::CheckoutService.new(order, params)
  #   result = service.process
  #
  # @return [Hash] { success: Boolean, order: Order, errors: Array, payment_data: Hash }
  class CheckoutService
    attr_reader :order, :params, :user, :errors
    
    def initialize(order, params = {})
      @order = order
      @params = params
      @user = order.user
      @errors = []
    end
    
    # Checkout işlemini başlat
    def process
      return validation_error unless validate_checkout
      
      order.transaction do
        # 1. Fiyatları hesapla
        calculate_prices!
        
        # 2. Adres bilgilerini kaydet
        save_addresses if params[:shipping_address].present? || params[:billing_address].present?
        
        # 3. Siparişi ödenmeye hazır hale getir
        prepare_order!
        
        # 4. Ödeme yöntemine göre işlem yap
        process_payment
      end
    rescue StandardError => e
      Rails.logger.error "Checkout error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      { success: false, errors: [e.message] }
    end
    
    # Sadece önizleme - işlem yapmadan sonuçları göster
    def preview
      return validation_error unless validate_checkout
      
      calculator = OrderPriceCalculator.new(order)
      preview_data = calculator.preview
      
      {
        success: true,
        preview: preview_data,
        payment_methods: available_payment_methods,
        can_use_balance: dealer_can_use_balance?,
        dealer_balance: user&.dealer? ? user.dealer_balance&.summary : nil
      }
    end
    
    private
    
    # Checkout validasyonu
    def validate_checkout
      @errors = []
      
      # Sepet boş mu?
      if order.order_lines.empty?
        @errors << 'Sepet boş'
        return false
      end
      
      # Sipariş durumu uygun mu?
      unless order.cart?
        @errors << 'Sipariş zaten işleme alınmış'
        return false
      end
      
      # Tüm ürünler stokta mı?
      unless order.all_items_in_stock?
        @errors << 'Bazı ürünler stokta yok'
        check_stock_details
        return false
      end
      
      # Ödeme yöntemi geçerli mi?
      if params[:payment_method].present? && !valid_payment_method?(params[:payment_method])
        @errors << 'Geçersiz ödeme yöntemi'
        return false
      end
      
      true
    end
    
    # Stok detaylarını kontrol et ve hata mesajlarına ekle
    def check_stock_details
      order.order_lines.each do |line|
        available = line.variant_id.present? ? line.variant.stock : line.product.total_stock
        if available < line.quantity
          @errors << "#{line.product_title}: İstenen miktar #{line.quantity}, stokta #{available}"
        end
      end
    end
    
    # Fiyatları hesapla
    def calculate_prices!
      calculator = OrderPriceCalculator.new(order)
      calculator.calculate!
      
      # Dealer indirimi varsa uygula (guest users için skip)
      apply_dealer_discount! if user&.dealer?
    end
    
    # Dealer indirimini uygula
    def apply_dealer_discount!
      return unless user&.dealer?
      
      total_discount_cents = 0
      
      order.order_lines.each do |line|
        discount = user.discount_for(line.product)
        next unless discount
        
        discount_amount = discount.discount_amount(line.total_cents)
        total_discount_cents += discount_amount
        
        # Satır notuna indirim bilgisini ekle
        line.update!(
          note: "#{line.note} | Dealer İndirimi: %#{discount.discount_percentage}"
        )
      end
      
      # Toplam indirimi siparişe kaydet (metadata olarak)
      order.update!(
        metadata: order.metadata.merge(
          dealer_discount_cents: total_discount_cents,
          dealer_discount_applied_at: Time.current
        )
      ) if total_discount_cents > 0
    end
    
    # Adres bilgilerini kaydet
    def save_addresses
      if params[:shipping_address].present?
        order.shipping_address = params[:shipping_address]
      end
      
      if params[:billing_address].present?
        order.billing_address = params[:billing_address]
      elsif params[:shipping_address].present? && !params[:use_different_billing]
        # Fatura adresi belirtilmemişse, kargo adresi ile aynı
        order.billing_address = params[:shipping_address]
      end
      
      order.save!
    end
    
    # Siparişi hazırla
    def prepare_order!
      # Sipariş notunu kaydet
      order.notes = params[:notes] if params[:notes].present?
      
      # Ödeme yöntemini kaydet
      order.payment_method = params[:payment_method] || 'credit_card'
      
      # Stokları rezerve et
      reserve_stock!
      
      order.save!
    end
    
    # Stokları rezerve et
    def reserve_stock!
      order.order_lines.each do |line|
        line.reserve_stock! if line.respond_to?(:reserve_stock!)
      end
    end
    
    # Ödeme işlemini yap
    def process_payment
      method = params[:payment_method] || 'credit_card'
      
      case method
      when 'credit_card', 'paytr'
        process_credit_card_payment
      when 'dealer_balance'
        process_dealer_balance_payment
      when 'bank_transfer'
        process_bank_transfer_payment
      when 'cash_on_delivery'
        process_cash_on_delivery_payment
      else
        { success: false, errors: ['Desteklenmeyen ödeme yöntemi'] }
      end
    end
    
    # Kredi kartı / PayTR ödemesi
    def process_credit_card_payment
      paytr_service = PaytrService.new(order)
      payment_response = paytr_service.create_payment_token
      
      unless payment_response[:success]
        return {
          success: false,
          errors: [payment_response[:error]]
        }
      end
      
      {
        success: true,
        order: order,
        payment_provider: 'paytr',
        payment_data: {
          token: payment_response[:token],
          iframe_url: payment_response[:iframe_url]
        },
        next_step: 'redirect_to_payment'
      }
    end
    
    # Dealer bakiyesi ile ödeme (B2B)
    def process_dealer_balance_payment
      unless user&.dealer?
        return { success: false, errors: ['Bu ödeme yöntemi sadece dealer hesaplar için geçerlidir'] }
      end
      
      balance = user.dealer_balance
      unless balance
        return { success: false, errors: ['Dealer bakiyesi bulunamadı'] }
      end
      
      # Bakiye yeterli mi?
      unless balance.available_balance_cents >= order.total_cents
        return {
          success: false,
          errors: [
            "Yetersiz bakiye. Gerekli: #{order.total.format}, Mevcut: #{balance.available_balance.format}"
          ]
        }
      end
      
      # Bakiyeden düş
      if balance.deduct!(order.total_cents, note: "Sipariş: #{order.order_number}", order_id: order.id)
        order.mark_as_paid!
        
        {
          success: true,
          order: order.reload,
          payment_method: 'dealer_balance',
          message: 'Sipariş dealer bakiyenizden ödenmiştir',
          remaining_balance: balance.reload.balance.format
        }
      else
        { success: false, errors: balance.errors.full_messages }
      end
    end
    
    # Havale/EFT ile ödeme
    def process_bank_transfer_payment
      order.mark_as_pending!
      
      order.update!(
        payment_method: 'bank_transfer',
        metadata: order.metadata.merge(
          payment_instructions: bank_transfer_instructions
        )
      )
      
      {
        success: true,
        order: order.reload,
        payment_method: 'bank_transfer',
        message: 'Sipariş alındı. Ödeme onayından sonra işleme alınacaktır',
        payment_instructions: bank_transfer_instructions
      }
    end
    
    # Kapıda ödeme
    def process_cash_on_delivery_payment
      # Kapıda ödeme sadece belirli tutarın altında olabilir
      max_amount = 500_00 # 500 TL
      
      if order.total_cents > max_amount
        return {
          success: false,
          errors: ["Kapıda ödeme maksimum #{Money.new(max_amount, order.currency).format} ile sınırlıdır"]
        }
      end
      
      order.mark_as_pending!
      
      order.update!(
        payment_method: 'cash_on_delivery'
      )
      
      {
        success: true,
        order: order.reload,
        payment_method: 'cash_on_delivery',
        message: 'Sipariş alındı. Ödemeyi kargo teslim alırken yapabilirsiniz'
      }
    end
    
    # Mevcut ödeme yöntemleri
    def available_payment_methods
      methods = [
        { id: 'credit_card', name: 'Kredi Kartı / Banka Kartı', enabled: true },
        { id: 'bank_transfer', name: 'Havale / EFT', enabled: true },
        { id: 'cash_on_delivery', name: 'Kapıda Ödeme', enabled: order.total_cents <= 500_00 }
      ]
      
      # Dealer ise bakiye ile ödeme seçeneği ekle (guest users için skip)
      if user&.dealer? && dealer_can_use_balance?
        methods << {
          id: 'dealer_balance',
          name: 'Dealer Bakiyesi',
          enabled: true,
          balance: user.dealer_balance&.balance&.format,
          available: user.dealer_balance&.available_balance&.format
        }
      end
      
      methods
    end
    
    # Dealer bakiye ile ödeyebilir mi?
    def dealer_can_use_balance?
      return false unless user&.dealer?
      return false unless user.dealer_balance
      
      user.dealer_balance.available_balance_cents >= order.total_cents
    end
    
    # Ödeme yöntemi geçerli mi?
    def valid_payment_method?(method)
      %w[credit_card paytr dealer_balance bank_transfer cash_on_delivery].include?(method)
    end
    
    # Havale talimatları
    def bank_transfer_instructions
      {
        bank_name: 'İş Bankası',
        branch: 'Kadıköy Şubesi',
        account_holder: 'Paksoy Menü Ltd. Şti.',
        iban: 'TR00 0000 0000 0000 0000 0000 00',
        reference: order.order_number,
        amount: order.total.format,
        note: 'Havale açıklamasına sipariş numaranızı yazmayı unutmayın'
      }
    end
    
    # Validasyon hatası döndür
    def validation_error
      { success: false, errors: @errors }
    end
  end
end
