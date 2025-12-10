module Api
  module V1
    module Admin
      class ShipmentsController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_shipment, only: [:show, :update]

        def index
          @shipments = Shipment.includes(:order).order(created_at: :desc)
          
          if params[:status].present?
            @shipments = @shipments.where(status: params[:status])
          end

          if params[:carrier].present?
            @shipments = @shipments.where(carrier: params[:carrier])
          end

          # Pagination could be added here
          
          render json: {
            status: 'success',
            data: @shipments.as_json(include: :order),
            meta: {
              total_count: @shipments.count
            }
          }
        end

        def show
          render json: {
            status: 'success',
            data: @shipment.as_json(include: :order)
          }
        end

        def update
          if @shipment.update(shipment_params)
            render json: {
              status: 'success',
              message: 'Kargo durumu güncellendi',
              data: @shipment
            }
          else
            render json: {
              status: 'error',
              message: 'Güncelleme başarısız',
              errors: @shipment.errors.full_messages
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

        def set_shipment
          @shipment = Shipment.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            status: 'error',
            message: 'Kargo kaydı bulunamadı'
          }, status: :not_found
        end

        def shipment_params
          params.require(:shipment).permit(:status, :tracking_number, :carrier, :notes)
        end
      end
    end
  end
end
