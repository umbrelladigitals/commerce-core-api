# frozen_string_literal: true

module Api
  module V1
    module Admin
      module Catalog
        class CategoriesController < ApplicationController
          before_action :authenticate_user!
          before_action :require_admin!
          before_action :set_category, only: [:show, :update, :destroy]

          # GET /api/v1/admin/catalog/categories
          def index
            @categories = ::Catalog::Category.includes(:parent, :children)
                                             .order(position: :asc, name: :asc)

            # Search
            if params[:search].present?
              search_term = "%#{params[:search]}%"
              @categories = @categories.where('name ILIKE ? OR description ILIKE ?', search_term, search_term)
            end

            # Filter by parent
            if params[:parent_id].present?
              @categories = @categories.where(parent_id: params[:parent_id])
            elsif params[:root_only] == 'true'
              @categories = @categories.where(parent_id: nil)
            end

            # Pagination
            page = params[:page] || 1
            @categories = @categories.page(page).per(params[:per_page] || 50)

            render json: {
              data: @categories.map { |category| serialize_category(category) },
              meta: {
                current_page: @categories.current_page,
                total_pages: @categories.total_pages,
                total_count: @categories.total_count
              }
            }
          end

          # GET /api/v1/admin/catalog/categories/:id
          def show
            render json: {
              data: serialize_category(@category, include_details: true)
            }
          end

          # POST /api/v1/admin/catalog/categories
          def create
            @category = ::Catalog::Category.new(category_params)

            if @category.save
              clear_categories_cache
              render json: {
                data: serialize_category(@category),
                message: 'Kategori oluşturuldu'
              }, status: :created
            else
              render json: {
                errors: @category.errors.full_messages
              }, status: :unprocessable_entity
            end
          end

          # PATCH/PUT /api/v1/admin/catalog/categories/:id
          def update
            if @category.update(category_params)
              clear_categories_cache
              render json: {
                data: serialize_category(@category),
                message: 'Kategori güncellendi'
              }
            else
              render json: {
                errors: @category.errors.full_messages
              }, status: :unprocessable_entity
            end
          end

          # DELETE /api/v1/admin/catalog/categories/:id
          def destroy
            if @category.children.exists?
              return render json: {
                error: 'Bu kategorinin alt kategorileri var, önce onları silin'
              }, status: :unprocessable_entity
            end

            if @category.products.exists?
              return render json: {
                error: 'Bu kategoride ürünler var, önce ürünleri başka kategoriye taşıyın'
              }, status: :unprocessable_entity
            end

            @category.destroy
            clear_categories_cache
            render json: { message: 'Kategori silindi' }
          end

          private

          def set_category
            @category = ::Catalog::Category.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'Kategori bulunamadı' }, status: :not_found
          end

          def category_params
            params.require(:category).permit(
              :name,
              :slug,
              :description,
              :parent_id,
              :position,
              :active,
              :image_url,
              :meta_title,
              :meta_description,
              :meta_keywords
            )
          end

          def serialize_category(category, include_details: false)
            data = {
              id: category.id,
              name: category.name,
              slug: category.slug,
              description: category.description,
              parent_id: category.parent_id,
              position: category.position,
              active: category.active,
              image_url: category.image_url,
              created_at: category.created_at,
              updated_at: category.updated_at
            }

            if include_details
              data[:products_count] = category.products.count
              data[:children_count] = category.children.count
              data[:parent] = category.parent ? {
                id: category.parent.id,
                name: category.parent.name,
                slug: category.parent.slug
              } : nil
              data[:children] = category.children.map { |child|
                {
                  id: child.id,
                  name: child.name,
                  slug: child.slug,
                  products_count: child.products.count
                }
              }
              data[:meta_title] = category.meta_title
              data[:meta_description] = category.meta_description
              data[:meta_keywords] = category.meta_keywords
            else
              data[:products_count] = category.products.count
              data[:children_count] = category.children.count
              data[:parent_name] = category.parent&.name
            end

            data
          end

          def clear_categories_cache
            Rails.cache.delete_matched("categories/*")
          end

          def require_admin!
            unless current_user.admin?
              render json: { error: 'Yetkisiz erişim' }, status: :forbidden
            end
          end
        end
      end
    end
  end
end
