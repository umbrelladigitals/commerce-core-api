# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProductOptionValuesController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_product_option
        before_action :set_product_option_value, only: [:show, :update, :destroy, :reorder]

        # GET /api/v1/admin/product_options/:product_option_id/values
        def index
          @values = @product_option.product_option_values.by_position

          render json: {
            success: true,
            data: {
              product_option_id: @product_option.id,
              product_option_name: @product_option.name,
              values_count: @values.count,
              price_range: @product_option.price_range,
              values: @values.map(&:as_json_api)
            }
          }, status: :ok
        end

        # GET /api/v1/admin/product_options/:product_option_id/values/:id
        def show
          render json: {
            success: true,
            data: @product_option_value.as_json_api
          }, status: :ok
        end

        # POST /api/v1/admin/product_options/:product_option_id/values
        def create
          @product_option_value = @product_option.product_option_values.build(product_option_value_params)

          if @product_option_value.save
            render json: {
              success: true,
              message: "Option value '#{@product_option_value.name}' created successfully",
              data: @product_option_value.as_json_api
            }, status: :created
          else
            render json: {
              success: false,
              errors: @product_option_value.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/product_options/:product_option_id/values/:id
        def update
          if @product_option_value.update(product_option_value_params)
            render json: {
              success: true,
              message: "Option value '#{@product_option_value.name}' updated successfully",
              data: @product_option_value.as_json_api
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @product_option_value.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/product_options/:product_option_id/values/:id
        def destroy
          value_name = @product_option_value.name
          
          if @product_option_value.destroy
            render json: {
              success: true,
              message: "Option value '#{value_name}' deleted successfully"
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @product_option_value.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/product_options/:product_option_id/values/:id/reorder
        # Body: { position: 2 }
        def reorder
          new_position = params[:position].to_i

          if @product_option_value.update(position: new_position)
            render json: {
              success: true,
              message: "Option value position updated to #{new_position}",
              data: @product_option_value.as_json_api
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @product_option_value.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def set_product_option
          @product_option = Catalog::ProductOption.find(params[:product_option_id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            success: false,
            error: "Product option not found"
          }, status: :not_found
        end

        def set_product_option_value
          @product_option_value = @product_option.product_option_values.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            success: false,
            error: "Option value not found"
          }, status: :not_found
        end

        def product_option_value_params
          params.require(:product_option_value).permit(
            :name,
            :price_cents,
            :price_mode,
            :position,
            meta: {}
          )
        end

        def require_admin!
          unless current_user&.admin?
            render json: {
              success: false,
              error: "Access denied. Admin privileges required."
            }, status: :forbidden
          end
        end
      end
    end
  end
end
