module Api
  module V1
    class SlidersController < Api::V1::BaseController
      before_action :set_slider, only: [:show, :update, :destroy]
      before_action :authenticate_user!, only: [:create, :update, :destroy]
      before_action :authorize_admin!, only: [:create, :update, :destroy]

      # GET /api/v1/sliders
      def index
        sliders = Slider.active.ordered
        render json: SliderSerializer.collection(sliders)
      end

      # GET /api/v1/sliders/:id
      def show
        render json: { data: SliderSerializer.new(@slider).as_json }
      end

      # POST /api/v1/sliders
      def create
        slider = Slider.new(slider_params)

        if slider.save
          render json: { data: SliderSerializer.new(slider).as_json }, status: :created
        else
          render json: { errors: slider.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/sliders/:id
      def update
        if @slider.update(slider_params)
          render json: { data: SliderSerializer.new(@slider).as_json }
        else
          render json: { errors: @slider.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/sliders/:id
      def destroy
        @slider.destroy
        head :no_content
      end

      private

      def set_slider
        @slider = Slider.find(params[:id])
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

      def authorize_admin!
        unless current_user&.admin?
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end
    end
  end
end
