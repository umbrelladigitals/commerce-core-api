module Api
  module V1
    class PaymentsController < ApplicationController
      # skip_before_action :authenticate_user!, only: [:callback, :iyzico_webhook]

      def create
        order = ::Orders::Order.find(params[:order_id])
        
        # Security check: Ensure order belongs to user if user is logged in
        if current_user && order.user_id != current_user.id
          return render json: { error: 'Unauthorized' }, status: :unauthorized
        end

        service = Payment::IyzicoService.new
        
        if params[:card_details].present?
          # Direct Payment (Custom Form)
          result = service.process_direct_payment(order, params[:card_details])
          
          if result['status'] == 'success'
            # Payment successful
            order.update!(
              status: :paid,
              payment_status: :paid,
              payment_method: 'iyzico_direct',
              paid_at: Time.current
            )
            
            render json: { status: 'success', message: 'Ödeme başarıyla alındı', order_id: order.id }
          else
            render json: { status: 'failure', message: result['errorMessage'] || 'Ödeme başarısız' }, status: :unprocessable_entity
          end
        else
          # Checkout Form (Iframe/Modal)
          # Callback URL points to our backend callback action
          callback_url = "#{request.base_url}/api/v1/payments/callback"
          
          result = service.initialize_checkout(order, callback_url)

          if result['status'] == 'success'
            render json: { 
              status: 'success', 
              html_content: result['checkoutFormContent'],
              token: result['token'],
              page_url: result['paymentPageUrl'] 
            }
          else
            render json: { status: 'failure', message: result['errorMessage'] }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Order not found' }, status: :not_found
      end

      def callback
        token = params[:token]
        
        Rails.logger.info "Iyzico Callback received with token: #{token}"
        
        options = Payment::IyzicoService.get_options
        
        request = {
          locale: Iyzipay::Model::Locale::TR,
          token: token
        }
        
        response = Iyzipay::Model::CheckoutForm.new.retrieve(request, options)
        
        # Parse the response - it's a RestClient::Response, need to parse JSON
        checkout_form_result = JSON.parse(response.to_s)
        
        Rails.logger.info "Iyzico Callback Result: #{checkout_form_result}"
        
        frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3001'

        if checkout_form_result['status'] == 'success'
           order_id = checkout_form_result['basketId']
           order = ::Orders::Order.find_by(id: order_id)
           
           if order
             order.update(
               status: :paid, 
               payment_status: 'paid', 
               paid_at: Time.current, 
               payment_method: 'iyzico',
               metadata: order.metadata.merge(iyzico_payment_id: checkout_form_result['paymentId'])
             )
             redirect_to "#{frontend_url}/checkout/success?order_id=#{order_id}", allow_other_host: true
           else
             redirect_to "#{frontend_url}/checkout/failure?message=OrderNotFound", allow_other_host: true
           end
        else
           error_message = checkout_form_result['errorMessage'] || 'Payment failed'
           redirect_to "#{frontend_url}/checkout/failure?message=#{URI.encode_www_form_component(error_message)}", allow_other_host: true
        end
      end

      def iyzico_webhook
        # Handle direct notification payload (from Iyzico webhook)
        if params[:paymentConversationId].present? && params[:status] == 'SUCCESS'
          order_id = params[:paymentConversationId]
          order = ::Orders::Order.find_by(id: order_id)

          if order
            unless order.paid?
              order.update(
                status: :paid,
                payment_status: 'paid',
                paid_at: Time.current,
                payment_method: 'iyzico_webhook',
                metadata: order.metadata.merge(iyzico_payment_id: params[:paymentId])
              )
            end
            return render json: { status: 'success', message: 'Webhook processed' }, status: :ok
          else
            return render json: { status: 'failure', message: 'Order not found' }, status: :not_found
          end
        end

        # Fallback: Check for token (Checkout Form flow)
        token = params[:token]
        
        if token.present?
          options = Payment::IyzicoService.get_options
          
          request = {
            locale: Iyzipay::Model::Locale::TR,
            token: token
          }
          
          response = Iyzipay::Model::CheckoutForm.new.retrieve(request, options)
          checkout_form_result = JSON.parse(response.to_s)
  
          if checkout_form_result['status'] == 'success'
             order_id = checkout_form_result['basketId']
             order = ::Orders::Order.find_by(id: order_id)
             
             if order
               # Idempotency check: if already paid, just return success
               unless order.paid?
                  order.update(
                    status: :paid, 
                    payment_status: 'paid', 
                    paid_at: Time.current, 
                    payment_method: 'iyzico',
                    metadata: order.metadata.merge(iyzico_payment_id: checkout_form_result['paymentId'])
                  )
               end
               render json: { status: 'success' }
             else
               render json: { status: 'failure', message: 'Order not found' }, status: :not_found
             end
          else
             render json: { status: 'failure', message: checkout_form_result['errorMessage'] }, status: :unprocessable_entity
          end
        else
          # No token and no valid payment payload
          render json: { status: 'ignored', message: 'Invalid payload' }, status: :ok
        end
      end
    end
  end
end
