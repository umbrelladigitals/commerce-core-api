# frozen_string_literal: true

module Api
  module V1
    module Catalog
      class VariantsController < Api::V1::BaseController
        before_action :set_product
        before_action :set_variant, only: [:show, :update, :destroy]
        before_action :authenticate_user!, only: [:create, :update, :destroy]

        # GET /api/products/:product_id/variants
        def index
          cache_key = "products/#{@product.id}/variants-#{@product.variants.maximum(:updated_at)&.to_i}"
          
          @variants = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
            variants_query = @product.variants.order(created_at: :desc)
            
            # Apply filters
            variants_query = variants_query.in_stock if params[:in_stock] == 'true'
            variants_query = variants_query.out_of_stock if params[:out_of_stock] == 'true'
            
            # Filter by specific option
            if params[:option_key].present? && params[:option_value].present?
              variants_query = variants_query.by_option(params[:option_key], params[:option_value])
            end
            
            variants_query.to_a
          end

          render json: ::Catalog::VariantSerializer.collection(@variants)
        end

        # GET /api/products/:product_id/variants/:id
        def show
          cache_key = "variants/#{@variant.id}-#{@variant.updated_at.to_i}"
          
          cached_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
            ::Catalog::VariantSerializer.new(@variant).as_json
          end

          render json: { data: cached_data }
        end

        # POST /api/products/:product_id/variants
        def create
          @variant = @product.variants.build(variant_params)

          if @variant.save
            clear_variants_cache
            render json: { 
              data: ::Catalog::VariantSerializer.new(@variant).as_json 
            }, status: :created
          else
            render json: { 
              errors: format_errors(@variant.errors) 
            }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/products/:product_id/variants/:id
        def update
          if @variant.update(variant_params)
            clear_variants_cache
            render json: { 
              data: ::Catalog::VariantSerializer.new(@variant).as_json 
            }
          else
            render json: { 
              errors: format_errors(@variant.errors) 
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/products/:product_id/variants/:id
        def destroy
          @variant.destroy
          clear_variants_cache
          head :no_content
        end

        # PATCH /api/products/:product_id/variants/:id/update_stock
        def update_stock
          set_variant
          new_stock = params[:stock].to_i

          if @variant.update(stock: new_stock)
            clear_variants_cache
            render json: { 
              data: ::Catalog::VariantSerializer.new(@variant).as_json 
            }
          else
            render json: { 
              errors: format_errors(@variant.errors) 
            }, status: :unprocessable_entity
          end
        end

        private

        def set_product
          @product = ::Catalog::Product.find(params[:product_id])
        rescue ActiveRecord::RecordNotFound
          render json: { 
            errors: [{ 
              status: '404', 
              title: 'Not Found', 
              detail: 'Product not found' 
            }] 
          }, status: :not_found
        end

        def set_variant
          @variant = @product.variants.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { 
            errors: [{ 
              status: '404', 
              title: 'Not Found', 
              detail: 'Variant not found' 
            }] 
          }, status: :not_found
        end

        def variant_params
          params.require(:variant).permit(:sku, :price_cents, :currency, :stock, options: {})
        end

        def clear_variants_cache
          Rails.cache.delete_matched("products/#{@product.id}/variants*")
          Rails.cache.delete_matched("variants/#{@variant.id}*") if @variant
          Rails.cache.delete_matched('products/*') # Also clear products cache
        end

        def format_errors(errors)
          errors.map do |attribute, message|
            {
              status: '422',
              source: { pointer: "/data/attributes/#{attribute}" },
              title: 'Validation Error',
              detail: message
            }
          end
        end
      end
    end
  end
end
