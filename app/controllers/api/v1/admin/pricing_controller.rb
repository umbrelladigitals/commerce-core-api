module Api
  module V1
    module Admin
      class PricingController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!

        def bulk_upload
          file = params[:file]
          if file.present?
            service = PricingImportService.new(file)
            results = service.process
            
            if results[:error_count] > 0 && results[:success_count] == 0
              render json: {
                status: 'error',
                message: 'İşlem sırasında hatalar oluştu',
                details: results
              }, status: :unprocessable_entity
            else
              render json: {
                status: 'success',
                message: "#{results[:success_count]} ürün güncellendi. #{results[:error_count]} hata oluştu.",
                details: results
              }
            end
          else
            render json: {
              status: 'error',
              message: 'Dosya yüklenemedi'
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
      end
    end
  end
end
