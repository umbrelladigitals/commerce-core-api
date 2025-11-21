# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      # GET /api/v1/categories
      def index
        @categories = ::Catalog::Category.all.order(name: :asc)
        
        render json: {
          data: @categories.map { |category| serialize_category(category) }
        }
      end
      
      # GET /api/v1/categories/:id
      def show
        @category = ::Catalog::Category.find(params[:id])
        
        render json: {
          data: serialize_category(@category, detailed: true)
        }
      end
      
      private
      
      def serialize_category(category, detailed: false)
        data = {
          id: category.id,
          name: category.name,
          slug: category.slug,
          parent_id: category.parent_id,
          created_at: category.created_at.iso8601,
          updated_at: category.updated_at.iso8601
        }
        
        if detailed
          data[:parent] = category.parent ? serialize_category(category.parent) : nil
          data[:children] = category.children.map { |c| serialize_category(c) } if category.respond_to?(:children)
          data[:products_count] = category.products.count if category.respond_to?(:products)
        end
        
        data
      end
    end
  end
end
