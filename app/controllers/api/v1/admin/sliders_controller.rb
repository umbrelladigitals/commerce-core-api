module Api
  module V1
    module Admin
      class SlidersController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_slider, only: [:show, :update, :destroy]

        def index
          @sliders = Slider.order(display_order: :asc)
          render json: {
            status: 'success',
            data: @sliders
          }
        end

        def show
          render json: {
            status: 'success',
            data: @slider
          }
        end

        def create
          @slider = Slider.new(slider_params)

          if @slider.save
            render json: {
              status: 'success',
              message: 'Slider başarıyla oluşturuldu',
              data: @slider
            }, status: :created
          else
            render json: {
              status: 'error',
              message: 'Slider oluşturulamadı',
              errors: @slider.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def update
          if @slider.update(slider_params)
            render json: {
              status: 'success',
              message: 'Slider güncellendi',
              data: @slider
            }
          else
            render json: {
              status: 'error',
              message: 'Güncelleme başarısız',
              errors: @slider.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        def destroy
          if @slider.destroy
            render json: {
              status: 'success',
              message: 'Slider silindi'
            }
          else
            render json: {
              status: 'error',
              message: 'Silme işlemi başarısız',
              errors: @slider.errors.full_messages
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

        def set_slider
          @slider = Slider.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            status: 'error',
            message: 'Slider bulunamadı'
          }, status: :not_found
        end

        def slider_params
          params.require(:slider).permit(
            :title,
            :subtitle,
            :button_text,
            :button_link,
            :image_url,
            :display_order,
            :active
          )
        end
      end
    end
  end
end
