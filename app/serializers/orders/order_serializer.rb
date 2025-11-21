# frozen_string_literal: true

module Orders
  # Order serializer for JSON:API format
  class OrderSerializer
    def self.render(order, options = {})
      {
        type: 'orders',
        id: order.id.to_s,
        attributes: {
          order_number: order.order_number,
          status: order.status,
          subtotal: order.subtotal.format,
          shipping: order.shipping.format,
          tax: order.tax.format,
          total: order.total.format,
          currency: order.currency,
          items_count: order.total_items,
          paid_at: order.paid_at,
          shipped_at: order.shipped_at,
          cancelled_at: order.cancelled_at,
          created_at: order.created_at,
          updated_at: order.updated_at
        },
        relationships: {
          user: {
            data: { type: 'users', id: order.user_id.to_s }
          },
          order_lines: {
            data: order.order_lines.map { |line| { type: 'order_lines', id: line.id.to_s } }
          }
        },
        links: {
          self: "/api/orders/#{order.id}"
        }
      }
    end
    
    def self.render_collection(orders)
      {
        data: orders.map { |order| render(order) },
        meta: {
          total: orders.size
        }
      }
    end
  end
end
