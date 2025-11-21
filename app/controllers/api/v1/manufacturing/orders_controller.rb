# frozen_string_literal: true

module Api
  module V1
    module Manufacturing
      class OrdersController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :set_order, only: [:show, :update_production_status]
        
        # GET /api/v1/manufacturing/orders
        # Sadece manufacturer rolü erişebilir
        def index
          authorize ::Orders::Order, policy_class: ::Manufacturing::OrderPolicy
          
          page = [params[:page].to_i, 1].max
          per_page = params[:per_page].to_i > 0 ? params[:page].to_i : 25
          
          orders = policy_scope(::Orders::Order, policy_scope_class: ::Manufacturing::OrderPolicy::Scope)
                     .includes(:user, :order_lines, :status_logs)
                     .order(created_at: :desc)
                     .limit(per_page)
                     .offset((page - 1) * per_page)
          
          render json: {
            data: orders.map { |order| 
              serialize_order(order)
            }
          }, status: :ok
        end
        
        # GET /api/v1/manufacturing/orders/:id
        def show
          authorize @order, policy_class: ::Manufacturing::OrderPolicy
          
          render json: {
            data: serialize_order(@order)
          }, status: :ok
        end
        
        # PATCH /api/v1/manufacturing/orders/:id/production_status
        # Üretim durumunu güncelle ve logla
        def update_production_status
          authorize @order, :update_status?, policy_class: ::Manufacturing::OrderPolicy
          
          new_status = params.require(:production_status)
          
          unless ::Orders::Order.production_statuses.keys.include?(new_status)
            return render json: {
              error: 'Invalid production status',
              valid_statuses: ::Orders::Order.production_statuses.keys
            }, status: :unprocessable_entity
          end
          
          @order.update_production_status!(new_status, current_user)
          
          render json: {
            data: serialize_order(@order.reload)
          }, status: :ok
          
        rescue Pundit::NotAuthorizedError => e
          render json: { error: 'Forbidden' }, status: :forbidden
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue StandardError => e
          render json: { error: e.message }, status: :internal_server_error
        end
        
        private
        
        def set_order
          @order = ::Orders::Order.includes(:user, :order_lines, :status_logs).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Order not found' }, status: :not_found
        end
        
        def serialize_order(order)
          {
            id: order.id.to_s,
            type: 'manufacturing_order',
            attributes: {
              order_number: order.order_number,
              status: order.status,
              production_status: order.production_status,
              total_items: order.total_items,
              paid_at: order.paid_at,
              shipped_at: order.shipped_at,
              cancelled_at: order.cancelled_at,
              created_at: order.created_at,
              updated_at: order.updated_at
              # Note: Fiyat alanları (total_cents, subtotal_cents, tax_cents, shipping_cents) kasıtlı olarak dahil edilmemiştir
            }
          }
        end
      end
    end
  end
end
