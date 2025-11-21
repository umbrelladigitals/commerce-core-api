# frozen_string_literal: true

module Manufacturing
  class OrderStatusLogSerializer
    def initialize(order_status_log, options = {})
      @order_status_log = order_status_log
      @options = options
    end
    
    def as_json
      {
        id: @order_status_log.id,
        from_status: @order_status_log.from_status,
        to_status: @order_status_log.to_status,
        changed_at: @order_status_log.changed_at,
        changed_by: changed_by_data
      }
    end
    
    private
    
    def changed_by_data
      return nil unless @order_status_log.user
      {
        id: @order_status_log.user.id,
        email: @order_status_log.user.email,
        name: @order_status_log.user.name
      }
    end
  end
end
