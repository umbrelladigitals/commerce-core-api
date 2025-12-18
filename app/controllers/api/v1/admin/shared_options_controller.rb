module Api
  module V1
    module Admin
      class SharedOptionsController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_shared_option, only: [:show, :update, :destroy]

        # GET /api/v1/admin/shared_options
        def index
          @shared_options = SharedOption.includes(:values).order(:position)

          render json: {
            success: true,
            data: @shared_options.map { |opt|
              opt.as_json(include: :values)
            }
          }, status: :ok
        end

        # GET /api/v1/admin/shared_options/:id
        def show
          render json: {
            success: true,
            data: @shared_option.as_json(include: :values)
          }, status: :ok
        end

        # POST /api/v1/admin/shared_options
        def create
          @shared_option = SharedOption.new(shared_option_params)

          if @shared_option.save
            render json: {
              success: true,
              message: "Shared option '#{@shared_option.name}' created successfully",
              data: @shared_option.as_json(include: :values)
            }, status: :created
          else
            render json: {
              success: false,
              errors: @shared_option.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PUT/PATCH /api/v1/admin/shared_options/:id
        def update
          if @shared_option.update(shared_option_params)
            render json: {
              success: true,
              message: "Shared option updated successfully",
              data: @shared_option.as_json(include: :values)
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @shared_option.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/shared_options/:id
        def destroy
          @shared_option.destroy
          render json: {
            success: true,
            message: "Shared option deleted successfully"
          }, status: :ok
        end

        private

        def require_admin!
          unless current_user&.admin?
            render json: {
              success: false,
              error: "Access denied. Admin privileges required."
            }, status: :forbidden
          end
        end

        def set_shared_option
          @shared_option = SharedOption.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { success: false, error: 'Shared option not found' }, status: :not_found
        end

        def shared_option_params
          params.require(:shared_option).permit(
            :name, :option_type, :required, :position,
            values_attributes: [:id, :name, :price_cents, :price_mode, :position, :_destroy]
          )
        end
      end
    end
  end
end
