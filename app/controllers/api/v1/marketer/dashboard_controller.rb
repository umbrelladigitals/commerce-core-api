# frozen_string_literal: true

module Api
  module V1
    module Marketer
      # Pazarlamacı dashboard ve istatistikleri
      class DashboardController < ApplicationController
        before_action :authenticate_user!
        before_action :require_marketer!

        # GET /api/v1/marketer/dashboard
        def index
          # Pazarlamacının oluşturduğu siparişler
          orders = ::Orders::Order.where(created_by_marketer_id: current_user.id)
          
          # İstatistikler
          today_orders = orders.where('created_at >= ?', Time.current.beginning_of_day).count
          this_week_orders = orders.where('created_at >= ?', Time.current.beginning_of_week).count
          this_month_orders = orders.where('created_at >= ?', Time.current.beginning_of_month).count
          total_orders = orders.count
          
          # Bu ay toplam satış
          this_month_sales = orders.where('created_at >= ?', Time.current.beginning_of_month)
                                   .where.not(status: [:cart, :cancelled])
                                   .sum(:total_cents)
          
          # Son siparişler
          recent_orders = orders.where.not(status: :cart)
                               .order(created_at: :desc)
                               .limit(10)
                               .includes(:user, :order_lines)

          render json: {
            data: {
              type: 'marketer_dashboard',
              attributes: {
                marketer_info: {
                  name: current_user.name,
                  email: current_user.email
                },
                statistics: {
                  today_orders: today_orders,
                  this_week_orders: this_week_orders,
                  this_month_orders: this_month_orders,
                  total_orders: total_orders,
                  this_month_sales: format_money(this_month_sales)
                },
                recent_orders: recent_orders.map do |order|
                  {
                    id: order.id,
                    order_number: order.id.to_s.rjust(6, '0'),
                    customer_name: order.user.name,
                    customer_email: order.user.email,
                    status: order.status,
                    total: format_money(order.total_cents),
                    items_count: order.order_lines.count,
                    created_at: order.created_at.iso8601
                  }
                end
              }
            }
          }, status: :ok
        end

        private

        def require_marketer!
          unless current_user&.marketer?
            render json: { error: 'Bu işlem için pazarlamacı yetkisi gereklidir' }, status: :forbidden
          end
        end

        def format_money(cents)
          "$#{'%.2f' % (cents / 100.0)}"
        end
      end
    end
  end
end
