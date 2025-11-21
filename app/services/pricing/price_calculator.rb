# frozen_string_literal: true

module Pricing
  # Fiyat hesaplama servisi (Variant + Options + Dealer Discount + Tax)
  #
  # Kullanım:
  #   calculator = Pricing::PriceCalculator.new(
  #     variant: variant,
  #     quantity: 2,
  #     selected_option_values: [option_value1, option_value2],
  #     dealer: user
  #   )
  #   result = calculator.call
  #
  # Hesaplama Sırası:
  # 1. Variant base price × quantity
  # 2. Dealer discount (DealerDiscount varsa)
  # 3. Product options (flat: 1×, per_unit: quantity×)
  # 4. KDV (configurable, default %20)
  #
  # Returns:
  # {
  #   unit_price_cents: 100000,
  #   quantity: 2,
  #   subtotal_cents: 200000,
  #   options_total_cents: 15000,
  #   discount_cents: 20000,
  #   subtotal_after_discount_cents: 195000,
  #   tax_rate: 0.20,
  #   tax_cents: 39000,
  #   total_cents: 234000,
  #   breakdown: {...}
  # }
  class PriceCalculator
    attr_reader :variant, :quantity, :selected_option_values, :dealer, :tax_rate
    
    # Default KDV oranı (%20)
    DEFAULT_TAX_RATE = 0.20
    
    # @param variant [Catalog::Variant] Variant objesi
    # @param quantity [Integer] Adet
    # @param selected_option_values [Array<Catalog::ProductOptionValue>] Seçilen opsiyon değerleri
    # @param dealer [User, nil] Dealer kullanıcı (opsiyonel)
    # @param tax_rate [Float] Vergi oranı (default: 0.20)
    def initialize(variant:, quantity: 1, selected_option_values: [], dealer: nil, tax_rate: DEFAULT_TAX_RATE)
      @variant = variant
      @quantity = quantity.to_i
      @selected_option_values = Array(selected_option_values)
      @dealer = dealer
      @tax_rate = tax_rate.to_f
      
      validate_inputs!
    end
    
    # Ana hesaplama metodu
    # @return [Hash] Detaylı fiyat breakdown'u
    def call
      # 1. Variant base price
      unit_price = variant.price_cents
      subtotal = unit_price * quantity
      
      # 2. Dealer discount
      discount_amount = calculate_dealer_discount(subtotal)
      subtotal_after_discount = subtotal - discount_amount
      
      # 3. Product options
      options_breakdown = calculate_options_total
      options_total = options_breakdown[:total_cents]
      
      # 4. Taxable amount (subtotal + options - discount)
      taxable_amount = subtotal_after_discount + options_total
      
      # 5. Tax
      tax_amount = calculate_tax(taxable_amount)
      
      # 6. Grand total
      grand_total = taxable_amount + tax_amount
      
      # Build result
      {
        # Base prices
        unit_price_cents: unit_price,
        unit_price: format_money(unit_price),
        quantity: quantity,
        subtotal_cents: subtotal,
        subtotal: format_money(subtotal),
        
        # Options
        options_total_cents: options_total,
        options_total: format_money(options_total),
        options_breakdown: options_breakdown[:items],
        
        # Discount
        discount_cents: discount_amount,
        discount: format_money(discount_amount),
        discount_percent: dealer_discount_percent,
        has_discount: discount_amount > 0,
        
        # After discount
        subtotal_after_discount_cents: subtotal_after_discount,
        subtotal_after_discount: format_money(subtotal_after_discount),
        
        # Tax
        tax_rate: tax_rate,
        tax_rate_percent: (tax_rate * 100).round(2),
        taxable_amount_cents: taxable_amount,
        taxable_amount: format_money(taxable_amount),
        tax_cents: tax_amount,
        tax: format_money(tax_amount),
        
        # Grand total
        total_cents: grand_total,
        total: format_money(grand_total),
        
        # Meta
        currency: variant.currency,
        is_dealer: dealer.present?,
        dealer_id: dealer&.id,
        
        # Detailed breakdown
        breakdown: build_breakdown(
          unit_price: unit_price,
          subtotal: subtotal,
          discount_amount: discount_amount,
          subtotal_after_discount: subtotal_after_discount,
          options_breakdown: options_breakdown,
          options_total: options_total,
          taxable_amount: taxable_amount,
          tax_amount: tax_amount,
          grand_total: grand_total
        )
      }
    end
    
    private
    
    # Dealer indirimi hesapla
    # @param subtotal [Integer] Ara toplam (cents)
    # @return [Integer] İndirim tutarı (cents)
    def calculate_dealer_discount(subtotal)
      return 0 unless dealer&.dealer?
      
      product = variant.product
      discount = dealer.discount_for(product)
      
      return 0 unless discount&.active?
      
      discount.discount_amount(subtotal)
    end
    
    # Dealer indirim yüzdesini al
    # @return [Float, nil]
    def dealer_discount_percent
      return nil unless dealer&.dealer?
      
      product = variant.product
      discount = dealer.discount_for(product)
      
      discount&.active? ? discount.discount_percent : nil
    end
    
    # Opsiyonların toplam fiyatını hesapla
    # @return [Hash] { total_cents: Integer, items: Array }
    def calculate_options_total
      total = 0
      items = []
      
      selected_option_values.each do |option_value|
        # Flat: Sadece 1 kere ekle
        # Per-unit: Quantity ile çarp
        price = option_value.calculate_price(quantity)
        
        total += price
        
        items << {
          option_id: option_value.product_option_id,
          option_name: option_value.product_option.name,
          value_id: option_value.id,
          value_name: option_value.name,
          price_mode: option_value.price_mode,
          unit_price_cents: option_value.price_cents,
          unit_price: format_money(option_value.price_cents),
          quantity: option_value.flat_price? ? 1 : quantity,
          total_cents: price,
          total: format_money(price)
        }
      end
      
      {
        total_cents: total,
        items: items
      }
    end
    
    # Vergi hesapla
    # @param taxable_amount [Integer] Vergilendirilecek tutar (cents)
    # @return [Integer] Vergi tutarı (cents)
    def calculate_tax(taxable_amount)
      (taxable_amount * tax_rate).round
    end
    
    # Para formatla
    # @param cents [Integer]
    # @return [String]
    def format_money(cents)
      Money.new(cents, variant.currency).format
    end
    
    # Detaylı breakdown oluştur
    def build_breakdown(unit_price:, subtotal:, discount_amount:, subtotal_after_discount:, 
                       options_breakdown:, options_total:, taxable_amount:, tax_amount:, grand_total:)
      {
        steps: [
          {
            step: 1,
            description: "Variant Base Price",
            calculation: "#{format_money(unit_price)} × #{quantity}",
            amount_cents: subtotal,
            amount: format_money(subtotal)
          },
          discount_amount > 0 ? {
            step: 2,
            description: "Dealer Discount (#{dealer_discount_percent}%)",
            calculation: "-#{format_money(discount_amount)}",
            amount_cents: -discount_amount,
            amount: "-#{format_money(discount_amount)}"
          } : nil,
          {
            step: discount_amount > 0 ? 3 : 2,
            description: "Subtotal After Discount",
            calculation: "#{format_money(subtotal)} - #{format_money(discount_amount)}",
            amount_cents: subtotal_after_discount,
            amount: format_money(subtotal_after_discount)
          },
          options_total > 0 ? {
            step: discount_amount > 0 ? 4 : 3,
            description: "Product Options",
            calculation: build_options_calculation(options_breakdown[:items]),
            amount_cents: options_total,
            amount: format_money(options_total),
            details: options_breakdown[:items]
          } : nil,
          {
            step: [discount_amount > 0, options_total > 0].count(true) + 3,
            description: "Taxable Amount",
            calculation: "#{format_money(subtotal_after_discount)} + #{format_money(options_total)}",
            amount_cents: taxable_amount,
            amount: format_money(taxable_amount)
          },
          {
            step: [discount_amount > 0, options_total > 0].count(true) + 4,
            description: "Tax (#{(tax_rate * 100).round}%)",
            calculation: "#{format_money(taxable_amount)} × #{(tax_rate * 100).round}%",
            amount_cents: tax_amount,
            amount: format_money(tax_amount)
          },
          {
            step: [discount_amount > 0, options_total > 0].count(true) + 5,
            description: "Grand Total",
            calculation: "#{format_money(taxable_amount)} + #{format_money(tax_amount)}",
            amount_cents: grand_total,
            amount: format_money(grand_total),
            is_total: true
          }
        ].compact,
        
        summary: {
          variant_price: format_money(subtotal),
          discount: discount_amount > 0 ? "-#{format_money(discount_amount)}" : "$0.00",
          options: format_money(options_total),
          subtotal: format_money(taxable_amount),
          tax: format_money(tax_amount),
          total: format_money(grand_total)
        }
      }
    end
    
    # Opsiyonlar için hesaplama string'i oluştur
    def build_options_calculation(options_items)
      return "No options" if options_items.empty?
      
      options_items.map do |item|
        if item[:price_mode] == 'flat'
          "#{item[:value_name]}: #{item[:unit_price]} (flat)"
        else
          "#{item[:value_name]}: #{item[:unit_price]} × #{item[:quantity]} (per-unit)"
        end
      end.join(" + ")
    end
    
    # Input validasyonu
    def validate_inputs!
      raise ArgumentError, "Variant is required" if variant.nil?
      raise ArgumentError, "Quantity must be positive" if quantity <= 0
      raise ArgumentError, "Tax rate must be between 0 and 1" if tax_rate < 0 || tax_rate > 1
      
      # Opsiyon değerlerinin aynı ürüne ait olduğunu kontrol et
      selected_option_values.each do |option_value|
        unless option_value.product_option.product_id == variant.product_id
          raise ArgumentError, "Option value #{option_value.id} does not belong to product #{variant.product_id}"
        end
      end
    end
  end
end
