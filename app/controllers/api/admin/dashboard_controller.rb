module Api
  module Admin
    class DashboardController < ApplicationController
      before_action :authenticate_user!
      before_action :ensure_admin

      def stats
        # Calculate stats
        total_orders = Order.count
        total_revenue_cents = Order.sum(:total_amount_cents)
        total_users = User.count
        total_products = Product.count
        
        # Calculate trends (last 30 days vs previous 30 days)
        last_30_days_orders = Order.where('created_at >= ?', 30.days.ago).count
        prev_30_days_orders = Order.where(created_at: 60.days.ago..30.days.ago).count
        order_trend = calculate_trend(last_30_days_orders, prev_30_days_orders)

        last_30_days_revenue = Order.where('created_at >= ?', 30.days.ago).sum(:total_amount_cents)
        prev_30_days_revenue = Order.where(created_at: 60.days.ago..30.days.ago).sum(:total_amount_cents)
        revenue_trend = calculate_trend(last_30_days_revenue, prev_30_days_revenue)

        render json: {
          data: {
            stats: {
              total_orders: { value: total_orders, trend: order_trend },
              total_revenue: { value: total_revenue_cents, trend: revenue_trend },
              total_users: { value: total_users, trend: 0 }, # Simplified
              total_products: { value: total_products, trend: 0 }
            },
            recent_orders: Order.includes(:user).order(created_at: :desc).limit(5).map do |order|
              {
                id: order.id,
                order_number: order.order_number,
                customer: order.user&.name || 'Guest',
                total_amount: order.total_amount_cents,
                status: order.status,
                created_at: order.created_at
              }
            end
          }
        }
      end

      private

      def calculate_trend(current, previous)
        return 0 if previous.zero?
        ((current - previous).to_f / previous * 100).round(1)
      end
    end
  end
end
