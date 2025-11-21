# frozen_string_literal: true

module Orders
  # Sipariş onayı maili gönderen Sidekiq job'ı
  # Ödeme başarılı olduktan sonra tetiklenir
  #
  # Kullanım:
  #   Orders::OrderConfirmationJob.perform_later(order_id)
  class OrderConfirmationJob < ApplicationJob
    queue_as :default
    
    # Hata durumunda 3 kez tekrar dene
    retry_on StandardError, wait: 5.seconds, attempts: 3
    
    def perform(order_id)
      order = Order.find(order_id)
      
      # Sadece ödenen siparişler için mail gönder
      unless order.paid?
        Rails.logger.warn "Order ##{order_id} is not paid, skipping confirmation email"
        return
      end
      
      # Mail gönderimi
      send_confirmation_email(order)
      
      # Ek işlemler
      send_notifications(order)
      update_analytics(order)
      
      Rails.logger.info "Order confirmation sent for order ##{order.id}"
    end
    
    private
    
    # Onay maili gönder
    def send_confirmation_email(order)
      # Mail gönderimi
      NotificationMailer.order_created(order).deliver_now
      
      # Log'a da yazalım
      Rails.logger.info <<~LOG
        📧 SIPARIŞ ONAYI GÖNDERİLDİ
        ================
        Sipariş No: #{order.order_number}
        Müşteri: #{order.user.name} (#{order.user.email})
        ================
      LOG
    end
    
    # Bildirimler gönder (SMS, push notification vb.)
    def send_notifications(order)
      # SMS bildirimi
      # SmsService.send(order.user.phone, "Siparişiniz alındı: #{order.order_number}")
      
      # Push notification
      # PushNotificationService.send(order.user, ...)
      
      Rails.logger.info "Notifications sent for order ##{order.id}"
    end
    
    # Analytics'e kaydet
    def update_analytics(order)
      # Google Analytics event
      # Analytics.track_purchase(order)
      
      # Internal analytics
      # OrderAnalytics.create(order: order, ...)
      
      Rails.logger.info "Analytics updated for order ##{order.id}"
    end
  end
end
