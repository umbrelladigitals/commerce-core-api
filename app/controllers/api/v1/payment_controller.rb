# frozen_string_literal: true

module Api
  module V1
    # Ödeme webhook'ları için controller
    # Stripe, PayTR veya diğer ödeme sağlayıcılarından gelen webhook'ları işler
    class PaymentController < ApplicationController
      before_action :authenticate_user!, only: [:confirm]
      # skip_before_action :verify_authenticity_token, only: [:paytr_callback, :paytr_success, :paytr_fail]
      
      # POST /api/payment/confirm
      # Manuel ödeme onayı (test için)
      # Normalde bu Stripe'dan webhook olarak gelir
      def confirm
        order = current_user.orders.find(params[:order_id])
        
        unless order.cart?
          return render json: { 
            error: 'Sipariş zaten işlemde' 
          }, status: :unprocessable_entity
        end
        
        # Siparişi ödenmiş olarak işaretle
        order.mark_as_paid!
        
        # Arka planda onay maili gönder
        Orders::OrderConfirmationJob.perform_later(order.id)
        
        render json: {
          message: 'Ödeme onaylandı',
          data: {
            type: 'orders',
            id: order.id.to_s,
            attributes: {
              order_number: order.order_number,
              status: order.status,
              total: order.total.format,
              paid_at: order.paid_at,
              created_at: order.created_at
            }
          },
          meta: {
            confirmation_email_sent: true
          }
        }, status: :ok
        
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Sipariş bulunamadı' }, status: :not_found
      end
      
      # POST /api/payment/webhook
      # Stripe webhook endpoint'i
      # Gerçek uygulamada Stripe imzası doğrulanmalı
      def webhook
        payload = request.body.read
        sig_header = request.env['HTTP_STRIPE_SIGNATURE']
        
        begin
          # Gerçek uygulamada:
          # event = Stripe::Webhook.construct_event(
          #   payload, sig_header, Rails.application.credentials.dig(:stripe, :webhook_secret)
          # )
          
          # Test için JSON parse
          event_data = JSON.parse(payload, symbolize_names: true)
          
          case event_data[:type]
          when 'payment_intent.succeeded'
            handle_payment_success(event_data[:data][:object])
          when 'payment_intent.payment_failed'
            handle_payment_failure(event_data[:data][:object])
          when 'charge.refunded'
            handle_refund(event_data[:data][:object])
          else
            Rails.logger.info "Unhandled webhook event: #{event_data[:type]}"
          end
          
          render json: { received: true }, status: :ok
          
        rescue JSON::ParserError => e
          render json: { error: 'Invalid payload' }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "Webhook error: #{e.message}"
          render json: { error: 'Webhook processing failed' }, status: :internal_server_error
        end
      end
      
      private
      
      # Ödeme başarılı olduğunda
      def handle_payment_success(payment_intent)
        # Order ID'yi payment_intent metadata'sından al
        order_id = payment_intent[:metadata][:order_id]
        return unless order_id
        
  order = ::Orders::Order.find_by(id: order_id)
        return unless order
        
        # Siparişi ödenmiş olarak işaretle
        order.mark_as_paid!
        
        # Onay maili gönder
        Orders::OrderConfirmationJob.perform_later(order.id)
        
        Rails.logger.info "Payment succeeded for order ##{order.id}"
      end
      
      # Ödeme başarısız olduğunda
      def handle_payment_failure(payment_intent)
        order_id = payment_intent[:metadata][:order_id]
        return unless order_id
        
  order = ::Orders::Order.find_by(id: order_id)
        return unless order
        
        # Stokları geri yükle
        order.restore_stock!
        
        Rails.logger.warn "Payment failed for order ##{order.id}"
        
        # Kullanıcıya bildirim gönderilebilir
        # OrderPaymentFailedJob.perform_later(order.id)
      end
      
      # İade işlemi
      def handle_refund(charge)
        # İade işlemi için gerekli mantık
        Rails.logger.info "Refund processed for charge #{charge[:id]}"
      end
      
      # POST /api/payment/paytr/callback
      # PayTR'dan gelen ödeme bildirimi (IPN)
      # Bu endpoint PayTR tarafından sunucu-sunucu iletişimi için çağrılır
      def paytr_callback
        # İmzayı doğrula
  unless ::Orders::PaytrService.verify_callback(params)
          Rails.logger.error "PayTR callback imza doğrulama hatası: #{params.inspect}"
          return render plain: "OK", status: :ok # PayTR'a OK dönmeliyiz aksi halde tekrar dener
        end
        
        # Sipariş numarasını parse et (ORDER-123 formatında)
        merchant_oid = params[:merchant_oid]
        order_id = merchant_oid.to_s.gsub("ORDER-", "").to_i
        
  order = ::Orders::Order.find_by(id: order_id)
        unless order
          Rails.logger.error "PayTR callback: Sipariş bulunamadı - #{merchant_oid}"
          return render plain: "OK", status: :ok
        end
        
        # Ödeme durumunu kontrol et
        payment_status = params[:status]
        
        case payment_status
        when "success"
          handle_paytr_success(order, params)
        when "failed"
          handle_paytr_failure(order, params)
        else
          Rails.logger.warn "PayTR callback: Bilinmeyen durum - #{payment_status}"
        end
        
        # PayTR'a her zaman OK dönmeliyiz
        render plain: "OK", status: :ok
        
      rescue StandardError => e
        Rails.logger.error "PayTR callback hatası: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render plain: "OK", status: :ok
      end
      
      # GET /api/payment/paytr/success
      # PayTR'dan başarılı ödeme sonrası kullanıcı yönlendirmesi
      def paytr_success
        merchant_oid = params[:merchant_oid]
        
        render json: {
          success: true,
          message: 'Ödemeniz başarıyla tamamlandı',
          data: {
            merchant_oid: merchant_oid
          }
        }, status: :ok
      end
      
      # GET /api/payment/paytr/fail
      # PayTR'dan başarısız ödeme sonrası kullanıcı yönlendirmesi
      def paytr_fail
        merchant_oid = params[:merchant_oid]
        failed_reason_code = params[:failed_reason_code]
        failed_reason_msg = params[:failed_reason_msg]
        
        render json: {
          success: false,
          message: 'Ödeme işlemi başarısız oldu',
          data: {
            merchant_oid: merchant_oid,
            reason_code: failed_reason_code,
            reason_message: failed_reason_msg
          }
        }, status: :ok
      end
      
      private
      
      # PayTR başarılı ödeme işlemi
      def handle_paytr_success(order, callback_params)
        return if order.paid? # Zaten ödenmiş
        
        # Siparişi ödenmiş olarak işaretle
        order.mark_as_paid!
        
        # Log oluştur
        Rails.logger.info "PayTR ödeme başarılı: Sipariş ##{order.id}, Tutar: #{callback_params[:total_amount]}"
        
        # Onay maili gönder
        Orders::OrderConfirmationJob.perform_later(order.id)
      end
      
      # PayTR başarısız ödeme işlemi
      def handle_paytr_failure(order, callback_params)
        return unless order.cart? # Sadece sepet durumunda stok iade et
        
        # Stokları geri yükle
        order.order_lines.each do |line|
          line.restore_stock!
        end
        
        Rails.logger.warn "PayTR ödeme başarısız: Sipariş ##{order.id}, Sebep: #{callback_params[:failed_reason_msg]}"
        
        # İsteğe bağlı: Kullanıcıya bildirim gönderilebilir
        # Orders::PaymentFailedJob.perform_later(order.id, callback_params[:failed_reason_msg])
      end
    end
  end
end
