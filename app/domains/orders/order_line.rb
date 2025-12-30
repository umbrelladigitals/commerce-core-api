# frozen_string_literal: true

module Orders
  class OrderLine < ApplicationRecord
    self.table_name = 'order_lines'
    
    # İlişkiler
    belongs_to :order
    belongs_to :product, class_name: 'Catalog::Product'
    belongs_to :variant, class_name: 'Catalog::Variant', optional: true
    
    # Para birimleri için Money-Rails entegrasyonu
    monetize :unit_price_cents, as: :unit_price
    monetize :total_cents, as: :total
    
    # Validasyonlar
    validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :unit_price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validate :variant_belongs_to_product
    validate :sufficient_stock
    
    # Callback'ler
    before_validation :set_prices, if: -> { new_record? || selected_options_changed? }
    before_validation :calculate_total
    after_save :update_order_totals
    after_destroy :update_order_totals
    
    # Delegasyonlar
    delegate :title, :sku, to: :product, prefix: true
    delegate :display_name, to: :variant, prefix: true, allow_nil: true
    
    # Ürün adı (variant varsa onunla birlikte)
    def item_name
      if variant.present?
        "#{product_title} - #{variant_display_name}"
      else
        product_title
      end
    end
    
    # Stok kontrolü yap
    def check_stock
      available = if variant.present?
        variant.stock
      else
        product.total_stock
      end
      
      { available: available, sufficient: available >= quantity }
    end
    
    # Stoktan düş
    def reserve_stock!
      return unless order.cart? # Sadece sepet aşamasında stok düş
      
      if variant.present?
        variant.decrement!(:stock, quantity)
      end
    end
    
    # Para birimi
    def currency
      order.currency
    end
    
    private
    
    # Fiyatları ayarla (variant varsa onun fiyatı, yoksa product'ın)
    def set_prices
      base_price = if variant.present?
        variant.price_cents
      else
        product.price_cents
      end

      # Seçilen opsiyonların fiyatlarını ekle (Sadece per_unit olanlar birim fiyata eklenir)
      per_unit_options_price = 0
      
      if selected_options.present? && selected_options.is_a?(Array)
        selected_options.each do |opt|
          # Varsayılan olarak per_unit kabul et
          mode = opt['price_mode'] || 'per_unit'
          
          if mode == 'per_unit' && opt['price_cents'].present?
            per_unit_options_price += opt['price_cents'].to_i
          end
        end
      end

      self.unit_price_cents = base_price + per_unit_options_price
    end
    
    # Toplam fiyatı hesapla
    def calculate_total
      return unless unit_price_cents && quantity
      
      # Flat (tek seferlik) ücretleri hesapla
      flat_options_price = 0
      
      if selected_options.present? && selected_options.is_a?(Array)
        selected_options.each do |opt|
          if opt['price_mode'] == 'flat' && opt['price_cents'].present?
            flat_options_price += opt['price_cents'].to_i
          end
        end
      end

      self.total_cents = (unit_price_cents * quantity) + flat_options_price
    end
    
    # Variant product'a ait mi kontrol et
    def variant_belongs_to_product
      return if variant.nil?
      
      if variant.product_id != product_id
        errors.add(:variant, 'does not belong to the specified product')
      end
    end
    
    # Yeterli stok var mı kontrol et
    def sufficient_stock
      return if order&.cancelled? # İptal edilen siparişlerde kontrol etme
      return if variant.nil? && product.variants.empty? # Variant olmayan ürünlerde stok kontrolü yapma
      
      stock_info = check_stock
      unless stock_info[:sufficient]
        errors.add(:quantity, "exceeds available stock (#{stock_info[:available]} available)")
      end
    end
    
    # Sipariş toplamlarını güncelle
    def update_order_totals
      return unless order
      
      # OrderPriceCalculator servisini kullanarak siparişi güncelle
      Orders::OrderPriceCalculator.new(order).calculate!
    end
  end
end
