# frozen_string_literal: true

module Api
  module V1
    class PricingController < Api::V1::BaseController
      # POST /api/v1/pricing/preview
      # Fiyat önizlemesi (variant + options + dealer discount + tax)
      #
      # Request Body:
      # {
      #   "variant_id": 1,
      #   "quantity": 2,
      #   "selected_options": {
      #     "1": 2,  # product_option_id => product_option_value_id
      #     "3": 5
      #   },
      #   "dealer_id": 3,  # optional
      #   "tax_rate": 0.18  # optional, default: 0.20
      # }
      #
      # Response:
      # {
      #   "success": true,
      #   "data": {
      #     "unit_price_cents": 100000,
      #     "quantity": 2,
      #     "subtotal_cents": 200000,
      #     "options_total_cents": 15000,
      #     "discount_cents": 20000,
      #     "tax_cents": 39000,
      #     "total_cents": 234000,
      #     "breakdown": { ... }
      #   }
      # }
      def preview
        # Parametreleri al
        variant_id = params[:variant_id]
        quantity = params[:quantity]&.to_i || 1
        selected_options = params[:selected_options] || {}
        dealer_id = params[:dealer_id]
        
        # Validasyon
        unless variant_id.present?
          return render json: {
            success: false,
            error: "variant_id is required"
          }, status: :unprocessable_entity
        end
        
        # Variant'ı bul
        variant = Catalog::Variant.find_by(id: variant_id)
        unless variant
          return render json: {
            success: false,
            error: "Variant not found"
          }, status: :not_found
        end
        
        # Tax rate: Önce parametreden, yoksa product'tan, yoksa default
        tax_rate = params[:tax_rate]&.to_f || 
                   variant.product.tax_rate&.to_f || 
                   Pricing::PriceCalculator::DEFAULT_TAX_RATE
        
        # Dealer'ı bul (opsiyonel)
        dealer = nil
        if dealer_id.present?
          dealer = User.find_by(id: dealer_id)
          unless dealer&.dealer?
            return render json: {
              success: false,
              error: "Invalid dealer_id. User must have dealer role."
            }, status: :unprocessable_entity
          end
        end
        
        # Seçilen option value'ları bul
        selected_option_values = []
        selected_options.each do |option_id, value_id|
          option = Catalog::ProductOption.find_by(id: option_id, product_id: variant.product_id)
          unless option
            return render json: {
              success: false,
              error: "Product option #{option_id} not found for this product"
            }, status: :not_found
          end
          
          value = option.product_option_values.find_by(id: value_id)
          unless value
            return render json: {
              success: false,
              error: "Option value #{value_id} not found for option #{option_id}"
            }, status: :not_found
          end
          
          selected_option_values << value
        end
        
        # Zorunlu opsiyonları kontrol et
        missing_required = check_required_options(variant.product, selected_options)
        if missing_required.any?
          return render json: {
            success: false,
            error: "Required options missing",
            missing_options: missing_required
          }, status: :unprocessable_entity
        end
        
        # Fiyat hesaplama servisini çağır
        calculator = Pricing::PriceCalculator.new(
          variant: variant,
          quantity: quantity,
          selected_option_values: selected_option_values,
          dealer: dealer,
          tax_rate: tax_rate
        )
        
        result = calculator.call
        
        # Response
        render json: {
          success: true,
          data: result,
          meta: {
            variant: {
              id: variant.id,
              sku: variant.sku,
              product_id: variant.product_id,
              product_title: variant.product.title
            },
            dealer: dealer ? {
              id: dealer.id,
              name: dealer.name,
              email: dealer.email
            } : nil,
            requested_at: Time.current.iso8601
          }
        }, status: :ok
        
      rescue ArgumentError => e
        render json: {
          success: false,
          error: e.message
        }, status: :unprocessable_entity
        
      rescue StandardError => e
        Rails.logger.error("Pricing preview error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        
        render json: {
          success: false,
          error: "An error occurred while calculating price",
          details: Rails.env.development? ? e.message : nil
        }, status: :internal_server_error
      end

      # POST /api/v1/pricing/cart-total
      # Sepet toplam fiyat hesaplama (tüm ürünler için)
      #
      # Request Body:
      # {
      #   "items": [
      #     {
      #       "variant_id": 1,
      #       "quantity": 2,
      #       "selected_options": { "1": 2 }
      #     },
      #     {
      #       "variant_id": 3,
      #       "quantity": 1
      #     }
      #   ],
      #   "dealer_id": 3  # optional
      # }
      def cart_total
        items = params[:items] || []
        dealer_id = params[:dealer_id]
        
        if items.empty?
          return render json: {
            success: false,
            error: "No items provided"
          }, status: :unprocessable_entity
        end
        
        # Dealer'ı bul (opsiyonel)
        dealer = nil
        if dealer_id.present?
          dealer = User.find_by(id: dealer_id)
        end
        
        # Her ürün için fiyat hesapla
        calculated_items = []
        total_subtotal_cents = 0
        total_discount_cents = 0
        total_tax_cents = 0
        
        items.each do |item|
          variant = Catalog::Variant.find_by(id: item[:variant_id])
          next unless variant
          
          quantity = item[:quantity]&.to_i || 1
          selected_options = item[:selected_options] || {}
          
          # Option value'ları bul
          selected_option_values = []
          selected_options.each do |option_id, value_id|
            option = Catalog::ProductOption.find_by(id: option_id, product_id: variant.product_id)
            next unless option
            value = option.product_option_values.find_by(id: value_id)
            selected_option_values << value if value
          end
          
          # Tax rate: Product'tan al veya default kullan
          tax_rate = variant.product.tax_rate&.to_f || Pricing::PriceCalculator::DEFAULT_TAX_RATE
          
          # Fiyat hesapla
          calculator = Pricing::PriceCalculator.new(
            variant: variant,
            quantity: quantity,
            selected_option_values: selected_option_values,
            dealer: dealer,
            tax_rate: tax_rate
          )
          
          result = calculator.call
          
          calculated_items << {
            variant_id: variant.id,
            unit_price_cents: result[:unit_price_cents],
            quantity: quantity,
            subtotal_cents: result[:subtotal_cents],
            discount_cents: result[:discount_cents],
            total_cents: result[:total_cents]
          }
          
          total_subtotal_cents += result[:subtotal_cents]
          total_discount_cents += result[:discount_cents]
          total_tax_cents += result[:tax_cents]
        end
        
        # Kargo ücreti (basit örnek - gerçek uygulamada adrese göre hesaplanmalı)
        shipping_cents = 0
        if total_subtotal_cents < 50000 # 500 TL altı siparişlere kargo ücreti
          shipping_cents = 2500 # 25 TL
        end
        
        total_cents = total_subtotal_cents - total_discount_cents + total_tax_cents + shipping_cents
        
        render json: {
          success: true,
          data: {
            items: calculated_items,
            subtotal_cents: total_subtotal_cents,
            discount_cents: total_discount_cents,
            shipping_cents: shipping_cents,
            tax_cents: total_tax_cents,
            total_cents: total_cents
          }
        }
      rescue StandardError => e
        Rails.logger.error("Cart total calculation error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        
        render json: {
          success: false,
          error: "An error occurred while calculating cart total",
          details: Rails.env.development? ? e.message : nil
        }, status: :internal_server_error
      end
      
      private
      
      # Zorunlu opsiyonların seçildiğini kontrol et
      # @param product [Catalog::Product]
      # @param selected_options [Hash] option_id => value_id
      # @return [Array<Hash>] Eksik zorunlu opsiyonlar
      def check_required_options(product, selected_options)
        missing = []
        
        product.required_options.each do |option|
          unless selected_options.key?(option.id.to_s) || selected_options.key?(option.id)
            missing << {
              option_id: option.id,
              option_name: option.name,
              option_type: option.option_type
            }
          end
        end
        
        missing
      end
    end
  end
end
