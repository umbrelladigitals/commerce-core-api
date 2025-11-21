# frozen_string_literal: true

module Api
  module V1
    module Orders
      class OrdersController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :set_order, only: [:show, :update, :cancel]

        def index
          @orders = current_user.orders.where.not(status: :cart).order(created_at: :desc)
          
          render json: {
            data: @orders.map do |order|
              {
                type: 'order',
                id: order.id.to_s,
                attributes: {
                  order_number: order.order_number,
                  status: order.status,
                  payment_method: order.payment_method,
                  payment_status: order.payment_status,
                  total: order.total.format,
                  currency: order.currency,
                  items_count: order.order_lines.count,
                  created_at: order.created_at,
                  paid_at: order.paid_at,
                  shipped_at: order.shipped_at,
                  shipping_address: order.shipping_address,
                  billing_address: order.billing_address
                }
              }
            end
          }, status: :ok
        end

        def show
          authorize @order, policy_class: ::Orders::OrderPolicy
          
          render json: {
            data: {
              type: 'order',
              id: @order.id.to_s,
              attributes: {
                order_number: @order.order_number,
                status: @order.status,
                payment_method: @order.payment_method,
                payment_status: @order.payment_status,
                subtotal: @order.subtotal.format,
                shipping: @order.shipping.format,
                tax: @order.tax.format,
                discount: @order.discount&.format,
                total: @order.total.format,
                currency: @order.currency,
                created_at: @order.created_at,
                paid_at: @order.paid_at,
                shipped_at: @order.shipped_at,
                shipping_address: @order.shipping_address,
                billing_address: @order.billing_address,
                notes: @order.notes
              }
            },
            included: @order.order_lines.includes(:product, :variant).map do |line|
              {
                type: 'order_line',
                id: line.id.to_s,
                attributes: {
                  product_id: line.product_id,
                  product_title: line.product_title,
                  variant_id: line.variant_id,
                  variant_name: line.variant&.display_name,
                  quantity: line.quantity,
                  unit_price: line.unit_price.format,
                  total: line.total.format
                }
              }
            end
          }, status: :ok
        end

        def create
          @order = current_user.orders.build(order_params)
          
          if @order.save
            render json: @order, status: :created
          else
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          authorize @order, policy_class: ::Orders::OrderPolicy
          
          if @order.update(order_params)
            render json: @order, status: :ok
          else
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def cancel
          authorize @order, policy_class: ::Orders::OrderPolicy
          
          if @order.update(status: :cancelled)
            render json: @order, status: :ok
          else
            render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        # Optional authentication - tries to authenticate but doesn't fail if token missing/invalid
        def authenticate_user_optional
          token = request.headers['Authorization']&.split(' ')&.last
          
          return unless token # No token provided, continue as guest
          
          begin
            secret_key = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
            decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
            payload = decoded.first
            
            @current_user = User.find_by(id: payload['sub'])
          rescue JWT::ExpiredSignature, JWT::DecodeError => e
            # Token invalid/expired, continue as guest
            Rails.logger.info "Optional auth failed: #{e.message}"
            @current_user = nil
          end
        end

        def set_order
          # Admin tüm siparişleri görebilir, diğer kullanıcılar sadece kendi siparişlerini
          if current_user.admin?
            @order = ::Orders::Order.find(params[:id])
          else
            @order = current_user.orders.find(params[:id])
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Sipariş bulunamadı veya erişim izniniz yok' }, status: :not_found
        end

        def order_params
          params.require(:order).permit(:status, :total_cents, :currency)
        end
      end
    end
  end
end
