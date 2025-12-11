# frozen_string_literal: true

module Api
  module V1
    module Catalog
      class ProductsController < Api::V1::BaseController
        before_action :set_product, only: [:show, :update, :destroy]
        before_action :authenticate_user!, only: [:create, :update, :destroy]

        # GET /api/products
        def index
          products_query = ::Catalog::Product.includes(:category, :variants).active
          
          # Apply filters
          products_query = products_query.in_category(params[:category_id]) if params[:category_id].present?
          products_query = products_query.search(params[:q]) if params[:q].present?
          products_query = products_query.discounted if params[:sale] == 'true' || params[:discounted] == 'true'
          
          # Pagination
          page = params[:page].to_i > 0 ? params[:page].to_i : 1
          per_page_param = params[:per_page].to_i
          per_page = per_page_param > 0 ? per_page_param.clamp(1, 100) : 20
          
          @products = products_query.order(created_at: :desc)
                       .limit(per_page)
                       .offset((page - 1) * per_page)
                       .to_a

          render json: ::Catalog::ProductSerializer.collection(@products)
        end

        # GET /api/products/:id
        def show
          serialized = ::Catalog::ProductSerializer.new(@product, include_variants: true).as_json
          
          # Opsiyonları ekle
          if @product.has_options?
            serialized[:options] = @product.options_with_values
            serialized[:has_options] = true
            serialized[:required_options_count] = @product.required_options.count
          else
            serialized[:options] = []
            serialized[:has_options] = false
          end
          
          # Reviews ekle (sadece approved)
          serialized[:average_rating] = @product.average_rating
          serialized[:reviews_count] = @product.reviews_count
          serialized[:reviews] = @product.approved_reviews.recent.limit(10).map do |review|
            {
              id: review.id,
              rating: review.rating,
              comment: review.comment,
              reviewer_name: review.reviewer_name,
              created_at: review.created_at
            }
          end

          render json: { data: serialized }
        end

        # POST /api/products
        def create
          @product = ::Catalog::Product.new(product_params)
          
          if @product.save
            clear_products_cache
            render json: { 
              data: ::Catalog::ProductSerializer.new(@product).as_json 
            }, status: :created
          else
            render json: { 
              errors: format_errors(@product.errors) 
            }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/products/:id
        def update
          if @product.update(product_params)
            clear_products_cache
            render json: { 
              data: ::Catalog::ProductSerializer.new(@product).as_json 
            }
          else
            render json: { 
              errors: format_errors(@product.errors) 
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/products/:id
        def destroy
          @product.destroy
          clear_products_cache
          head :no_content
        end

        private

        def set_product
          # Try to find by slug first, then by ID for backward compatibility
          @product = if params[:id] =~ /\A\d+\z/
                      ::Catalog::Product.find(params[:id])
                    else
                      ::Catalog::Product.find_by_slug!(params[:id])
                    end
        rescue ActiveRecord::RecordNotFound
          render json: { 
            errors: [{ 
              status: '404', 
              title: 'Not Found', 
              detail: 'Product not found' 
            }] 
          }, status: :not_found
        end

        def product_params
          params.require(:product).permit(
            :title, :description, :sku, :price_cents, :currency, :active, :category_id
          )
        end

        def clear_products_cache
          Rails.cache.delete_matched('products/*')
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
