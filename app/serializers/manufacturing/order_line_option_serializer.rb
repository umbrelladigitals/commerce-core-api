# frozen_string_literal: true

module Manufacturing
  class OrderLineOptionSerializer
    def initialize(order_line_option, options = {})
      @order_line_option = order_line_option
      @options = options
    end
    
    def as_json
      {
        id: @order_line_option.id,
        quantity: @order_line_option.quantity,
        option_name: @order_line_option.product_option&.name,
        option_value: @order_line_option.product_option_value&.value,
        product_option: product_option_data,
        product_option_value: product_option_value_data
      }
      # Note: Fiyat bilgileri (option_price_cents) kasıtlı olarak dahil edilmemiştir
    end
    
    private
    
    def product_option_data
      return nil unless @order_line_option.product_option
      {
        id: @order_line_option.product_option.id,
        name: @order_line_option.product_option.name
      }
    end
    
    def product_option_value_data
      return nil unless @order_line_option.product_option_value
      {
        id: @order_line_option.product_option_value.id,
        value: @order_line_option.product_option_value.value
      }
    end
  end
end
