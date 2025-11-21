class NotificationMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'noreply@commerce.com')

  def send_notification(to:, subject:, body:)
    @body = body
    
    mail(
      to: to,
      subject: subject
    )
  end

  def order_created(order)
    @order = order
    @user = order.user
    
    mail(
      to: @user.email,
      subject: "Siparişiniz Alındı - ##{@order.order_number}"
    )
  end

  def order_shipped(order)
    @order = order
    @user = order.user
    @shipment = order.shipment
    
    mail(
      to: @user.email,
      subject: "Siparişiniz Kargoya Verildi - ##{@order.order_number}"
    )
  end
end
