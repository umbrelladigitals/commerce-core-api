# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProductsController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_product, only: [:show, :update, :destroy]

        # GET /api/v1/admin/products
        def index
          @products = ::Catalog::Product.includes(:category)
          
          # Search
          if params[:search].present?
            @products = @products.where(
              "title ILIKE ? OR sku ILIKE ? OR description ILIKE ?",
              "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
            )
          end
          
          # Filters
          @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
          @products = @products.where(active: params[:active]) if params[:active].present?
          
          # Pagination
          page = params[:page]&.to_i || 1
          per_page = params[:per_page]&.to_i || 20
          per_page = [per_page, 100].min # Max 100 per page
          
          total_count = @products.count
          total_pages = (total_count.to_f / per_page).ceil
          offset = (page - 1) * per_page
          
          @products = @products.offset(offset).limit(per_page)
          
          render json: {
            data: @products.map { |product| serialize_product(product) },
            meta: {
              current_page: page,
              total_pages: total_pages,
              total_count: total_count,
              per_page: per_page
            }
          }
        end

        # GET /api/v1/admin/products/:id
        def show
          render json: serialize_product(@product, detailed: true)
        end

        # POST /api/v1/admin/products
        def create
          @product = ::Catalog::Product.new(product_params)
          
          if @product.save
            # Handle initial stock for simple products
            stock_value = params[:stock] || params.dig(:product, :stock)
            if stock_value.present? && @product.variants.empty?
               @product.variants.create!(
                 sku: @product.sku,
                 price_cents: @product.price_cents,
                 stock: stock_value.to_i
               )
            end

            render json: serialize_product(@product, detailed: true), status: :created
          else
            render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/admin/products/:id
        def update
          # Handle quick stock update
          stock_value = params[:stock] || params.dig(:product, :stock)

          if stock_value.present?
            stock_val = stock_value.to_i
            
            # If product has variants, update the first one (usually the main one for simple products)
            variant = @product.variants.first
            
            if variant
              variant.update(stock: stock_val)
            elsif @product.variants.empty?
               # Create a default variant if none exists
               @product.variants.create!(
                 sku: @product.sku,
                 price_cents: @product.price_cents,
                 stock: stock_val
               )
            end
            
            @product.reload
          end

          if @product.update(product_params)
            render json: serialize_product(@product, detailed: true)
          else
            render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/products/:id
        def destroy
          if @product.destroy
            head :no_content
          else
            render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def set_product
          @product = ::Catalog::Product.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Product not found' }, status: :not_found
        end

        def product_params
          params.require(:product).permit(
            :title,
            :slug,
            :description,
            :short_description,
            :sku,
            :sku_prefix,
            :price_cents,
            :base_price_cents,
            :cost_price_cents,
            :currency,
            :active,
            :category_id,
            :brand,
            :tax_rate,
            :featured,
            :meta_title,
            :meta_description,
            tags: [],
            images: [],
            properties: {},
            variants_attributes: [:id, :sku, :price_cents, :stock, :_destroy, options: {}],
            product_options_attributes: [
              :id, :name, :option_type, :required, :position, :_destroy,
              product_option_values_attributes: [:id, :name, :price_cents, :price_mode, :position, :_destroy]
            ]
          )
        end

        def require_admin!
          unless current_user.admin?
            render json: { error: 'Admin access required' }, status: :forbidden
          end
        end

        def serialize_product(product, detailed: false)
          variants = product.respond_to?(:variants) ? product.variants : []
          total_stock = variants.sum { |v| v.stock || 0 }
          
          data = {
            id: product.id,
            name: product.title,
            slug: product.slug || product.title.parameterize,
            description: product.description,
            short_description: product.short_description,
            sku: product.sku,
            sku_prefix: product.sku_prefix,
            price_cents: product.price_cents,
            base_price_cents: product.base_price_cents || product.price_cents,
            cost_price_cents: product.cost_price_cents,
            price: product.price&.format || "#{product.currency} #{product.price_cents / 100.0}",
            currency: product.currency,
            stock: 0, # Legacy field
            total_stock: total_stock,
            status: product.active? ? 'active' : 'inactive',
            is_active: product.active?,
            category: product.category&.name,
            category_id: product.category_id,
            category_name: product.category&.name,
            brand: product.brand,
            images: product.images.attached? ? product.images.map { |img| { url: url_for(img), signed_id: img.signed_id } } : [],
            tax_rate: product.tax_rate&.to_f,
            featured: product.featured || false,
            tags: product.tags || [],
            properties: product.properties || {},
            meta_title: product.meta_title,
            meta_description: product.meta_description,
            created_at: product.created_at.iso8601,
            updated_at: product.updated_at.iso8601
          }
          
          if detailed
            data[:variants] = variants.map { |v| serialize_variant(v) }
            data[:options] = product.product_options.map { |opt| serialize_option(opt) } if product.respond_to?(:product_options)
          end
          
          data
        end

        def serialize_variant(variant)
          {
            id: variant.id,
            sku: variant.sku,
            options: variant.options || {},
            price_cents: variant.price_cents,
            stock: variant.stock || 0,
            active: variant.try(:active) != false
          }
        end

        def serialize_option(option)
          {
            id: option.id,
            name: option.name,
            option_type: option.option_type,
            required: option.required,
            position: option.position,
            values: option.product_option_values.map { |v| serialize_option_value(v) }
          }
        end

        def serialize_option_value(value)
          {
            id: value.id,
            name: value.name,
            price_cents: value.price_cents,
            price_mode: value.price_mode,
            position: value.position
          }
        end
      end
    end
  end
end
