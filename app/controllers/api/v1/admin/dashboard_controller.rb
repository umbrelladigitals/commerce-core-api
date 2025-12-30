module Api
  module V1
    module Admin
      class DashboardController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!

        def stats
          # Placeholder stats
          render json: {
            total_orders: ::Orders::Order.count,
            total_products: ::Catalog::Product.count,
            total_users: ::User.count,
            total_revenue: ::Orders::Order.sum(:total_cents),
            recent_orders: ::Orders::Order.order(created_at: :desc).limit(5).map { |o| 
              {
                id: o.id,
                customer: o.user&.email,
                total: o.total.format,
                status: o.status,
                date: o.created_at
              }
            }
          }
        end

        private

        def require_admin!
          unless current_user&.admin?
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
      end
    end
  end
end
