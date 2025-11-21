# frozen_string_literal: true

module Manufacturing
  class OrderLineSerializer
    def initialize(order_line, options = {})
      @order_line = order_line
      @options = options
    end
    
    def as_json
      {
        id: @order_line.id,
        quantity: @order_line.quantity,
        product_name: @order_line.product&.name,
        variant_name: @order_line.variant&.name,
        created_at: @order_line.created_at,
        updated_at: @order_line.updated_at,
        product: product_data,
        variant: variant_data,
        selected_options: selected_options_data
      }
      # Note: unit_price_cents, line_total_cents gibi fiyat alanları 
      # kasıtlı olarak dahil edilmemiştir
    end
    
    private
    
    def product_data
      return nil unless @order_line.product
      {
        id: @order_line.product.id,
        name: @order_line.product.name,
        sku: @order_line.product.sku
      }
    end
    
    def variant_data
      return nil unless @order_line.variant
      {
        id: @order_line.variant.id,
        name: @order_line.variant.name,
        sku: @order_line.variant.sku
      }
    end
    
    def selected_options_data
      return [] unless @options[:include]&.include?(:selected_options)
      @order_line.selected_options.map do |option|
        OrderLineOptionSerializer.new(option).as_json
      end
    end
  end
end
