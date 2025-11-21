# frozen_string_literal: true

module Api
  module V1
    module Catalog
      class CategoriesController < Api::V1::BaseController
        before_action :set_category, only: [:show, :update, :destroy]
        before_action :authenticate_user!, only: [:create, :update, :destroy]

        # GET /api/categories
        def index
          cache_key = "categories/all-#{Catalog::Category.maximum(:updated_at)&.to_i}"
          
          @categories = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
            Catalog::Category.includes(:children, :products)
                            .order(created_at: :desc)
                            .all
                            .to_a
          end

          render json: Catalog::CategorySerializer.collection(@categories, include_products_count: true)
        end

        # GET /api/categories/:id
        def show
          cache_key = "categories/#{@category.id}-#{@category.updated_at.to_i}"
          
          cached_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
            Catalog::CategorySerializer.new(@category, include_children: true, include_products_count: true).as_json
          end

          render json: { data: cached_data }
        end

        # POST /api/categories
        def create
          @category = Catalog::Category.new(category_params)

          if @category.save
            clear_categories_cache
            render json: { data: Catalog::CategorySerializer.new(@category).as_json }, status: :created
          else
            render json: { 
              errors: format_errors(@category.errors) 
            }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/categories/:id
        def update
          if @category.update(category_params)
            clear_categories_cache
            render json: { data: Catalog::CategorySerializer.new(@category).as_json }
          else
            render json: { 
              errors: format_errors(@category.errors) 
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/categories/:id
        def destroy
          @category.destroy
          clear_categories_cache
          head :no_content
        end

        # GET /api/categories/:id/products
        def products
          @category = Catalog::Category.find(params[:id])
          @products = @category.products.active.includes(:variants)

          render json: Catalog::ProductSerializer.collection(@products)
        end

        private

        def set_category
          @category = Catalog::Category.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { 
            errors: [{ 
              status: '404', 
              title: 'Not Found', 
              detail: 'Category not found' 
            }] 
          }, status: :not_found
        end

        def category_params
          params.require(:category).permit(:name, :slug, :parent_id)
        end

        def clear_categories_cache
          Rails.cache.delete_matched('categories/*')
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
