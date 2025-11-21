# frozen_string_literal: true

module Manufacturing
  class OrderSerializer
    def initialize(order, options = {})
      @order = order
      @options = options
    end
    
    def as_json
      {
        id: @order.id,
        order_number: @order.order_number,
        status: @order.status,
        production_status: @order.production_status,
        total_items: @order.total_items,
        paid_at: @order.paid_at,
        shipped_at: @order.shipped_at,
        cancelled_at: @order.cancelled_at,
        created_at: @order.created_at,
        updated_at: @order.updated_at,
        user: user_data,
        order_lines: order_lines_data,
        status_logs: status_logs_data
      }
      # Note: Fiyat alanları (total_cents, subtotal_cents, tax_cents, shipping_cents) 
      # kasıtlı olarak dahil edilmemiştir
    end
    
    private
    
    def user_data
      return nil unless @order.user
      {
        id: @order.user.id,
        email: @order.user.email,
        name: @order.user.name
      }
    end
    
    def order_lines_data
      return [] unless @options[:include]&.include?(:order_lines)
      @order.order_lines.map do |line|
        OrderLineSerializer.new(line).as_json
      end
    end
    
    def status_logs_data
      return [] unless @options[:include]&.include?(:status_logs)
      @order.status_logs.map do |log|
        OrderStatusLogSerializer.new(log).as_json
      end
    end
  end
end
