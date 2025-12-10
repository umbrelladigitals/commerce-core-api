module Api
  module V1
    module Admin
      class CouponsController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_coupon, only: [:show, :destroy]

        def index
          @coupons = Promotions::Coupon.all.order(created_at: :desc)
          render json: {
            status: 'success',
            data: @coupons
          }
        end

        def show
          render json: {
            status: 'success',
            data: @coupon
          }
        end

        def create
          @coupon = Promotions::Coupon.new(coupon_params)

          if @coupon.save
            render json: {
              status: 'success',
              message: 'Kupon başarıyla oluşturuldu',
              data: @coupon
            }, status: :created
          else
            render json: {
              status: 'error',
              message: 'Kupon oluşturulamadı',
              errors: @coupon.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def destroy
          if @coupon.destroy
            render json: {
              status: 'success',
              message: 'Kupon başarıyla silindi'
            }
          else
            render json: {
              status: 'error',
              message: 'Kupon silinemedi',
              errors: @coupon.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def require_admin!
          unless current_user&.role == 'admin'
            render json: {
              status: 'error',
              message: 'Bu işlem için yetkiniz yok'
            }, status: :forbidden
          end
        end

        def set_coupon
          @coupon = Promotions::Coupon.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            status: 'error',
            message: 'Kupon bulunamadı'
          }, status: :not_found
        end

        def coupon_params
          params.require(:coupon).permit(
            :code,
            :discount_type,
            :value,
            :min_order_amount_cents,
            :starts_at,
            :ends_at,
            :active,
            :usage_limit
          )
        end
      end
    end
  end
end
