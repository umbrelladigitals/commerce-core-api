class OrderStatusChangedJob < ApplicationJob
  queue_as :notifications

  def perform(order_id, from_status, to_status)
    order = Orders::Order.find(order_id)
    user = order.user
    
    return unless user&.email.present?
    
    # Find appropriate template based on new status
    template_name = "order_status_#{to_status}"
    template = NotificationTemplate.active.find_by(name: template_name, channel: 'email')
    
    return unless template
    
    # Prepare variables for template
    variables = {
      order_id: order.id,
      order_number: order.order_number,
      customer_name: user.name,
      customer_email: user.email,
      status: to_status,
      previous_status: from_status,
      tracking: order.tracking_number || 'N/A',
      total: Money.new(order.total_cents, 'USD').format,
      order_date: order.created_at.strftime('%B %d, %Y')
    }
    
    # Send notification
    NotificationSender.new(
      template: template,
      recipient: user.email,
      variables: variables,
      user: user
    ).send!
    
    Rails.logger.info("Order status notification sent for order ##{order.id}: #{from_status} → #{to_status}")
  rescue StandardError => e
    Rails.logger.error("Failed to send order status notification: #{e.message}")
    raise e
  end
end
