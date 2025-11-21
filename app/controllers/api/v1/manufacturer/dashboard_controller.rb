# frozen_string_literal: true

module Api
  module V1
    module Manufacturer
      class DashboardController < ApplicationController
        before_action :authenticate_user!
        before_action :require_manufacturer!

        def index
          # Üretim durumuna göre istatistikler
          stats = {
            pending_orders: orders_scope.production_status_pending.count,
            in_production_orders: orders_scope.production_status_in_production.count,
            ready_orders: orders_scope.production_status_ready.count,
            shipped_today: orders_scope.production_status_shipped.where('orders.updated_at >= ?', Time.current.beginning_of_day).count,
            total_production_orders: orders_scope.count
          }

          # Son 10 üretim siparişi
          recent_orders = orders_scope
                           .includes(:user, :order_lines)
                           .order(created_at: :desc)
                           .limit(10)
                           .map { |order| serialize_order_summary(order) }

          render json: {
            data: {
              type: 'manufacturer_dashboard',
              attributes: {
                statistics: stats,
                recent_orders: recent_orders
              }
            }
          }, status: :ok
        end

        private

        def orders_scope
          # Sadece ödeme alınmış ve iptal edilmemiş siparişler üretim için geçerli
          ::Orders::Order.where(status: [:paid, :shipped])
                        .where.not(status: :cancelled)
        end

        def require_manufacturer!
          unless current_user&.manufacturer?
            render json: { error: 'Unauthorized - Manufacturer access required' }, status: :forbidden
          end
        end

        def serialize_order_summary(order)
          {
            id: order.id,
            order_number: order.order_number,
            customer_name: order.user&.name || 'Guest',
            customer_email: order.user&.email,
            production_status: order.production_status,
            status: order.status,
            items_count: order.order_lines.sum(:quantity),
            total: format_money(order.total),
            created_at: order.created_at.iso8601,
            updated_at: order.updated_at.iso8601
          }
        end

        def format_money(amount)
          {
            amount: amount.cents,
            formatted: amount.format
          }
        end
      end
    end
  end
end
