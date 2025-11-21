# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProductOptionsController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_product
        before_action :set_product_option, only: [:show, :update, :destroy, :reorder]

        # GET /api/v1/admin/products/:product_id/product_options
        def index
          @product_options = @product.product_options.includes(:product_option_values)

          render json: {
            success: true,
            data: {
              product_id: @product.id,
              product_title: @product.title,
              options_count: @product_options.count,
              options: @product_options.map(&:as_json_api)
            }
          }, status: :ok
        end

        # GET /api/v1/admin/products/:product_id/product_options/:id
        def show
          render json: {
            success: true,
            data: @product_option.as_json_api
          }, status: :ok
        end

        # POST /api/v1/admin/products/:product_id/product_options
        def create
          @product_option = @product.product_options.build(product_option_params)

          if @product_option.save
            render json: {
              success: true,
              message: "Product option '#{@product_option.name}' created successfully",
              data: @product_option.as_json_api
            }, status: :created
          else
            render json: {
              success: false,
              errors: @product_option.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/products/:product_id/product_options/:id
        def update
          if @product_option.update(product_option_params)
            render json: {
              success: true,
              message: "Product option '#{@product_option.name}' updated successfully",
              data: @product_option.as_json_api
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @product_option.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/products/:product_id/product_options/:id
        def destroy
          option_name = @product_option.name
          
          if @product_option.destroy
            render json: {
              success: true,
              message: "Product option '#{option_name}' deleted successfully"
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @product_option.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/products/:product_id/product_options/:id/reorder
        # Body: { position: 2 }
        def reorder
          new_position = params[:position].to_i

          if @product_option.update(position: new_position)
            render json: {
              success: true,
              message: "Product option position updated to #{new_position}",
              data: @product_option.as_json_api
            }, status: :ok
          else
            render json: {
              success: false,
              errors: @product_option.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def set_product
          @product = Catalog::Product.find(params[:product_id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            success: false,
            error: "Product not found"
          }, status: :not_found
        end

        def set_product_option
          @product_option = @product.product_options.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            success: false,
            error: "Product option not found"
          }, status: :not_found
        end

        def product_option_params
          params.require(:product_option).permit(
            :name,
            :option_type,
            :required,
            :position
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
