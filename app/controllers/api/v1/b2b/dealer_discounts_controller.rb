# frozen_string_literal: true

module Api
  module V1
    module B2b
      # Dealer indirimleri yönetimi controller'ı
      # Admin ve dealer'lar tarafından kullanılır
      class DealerDiscountsController < ApplicationController
        before_action :authenticate_user!
        before_action :set_discount, only: [:show, :update, :destroy, :toggle_active]
        before_action :authorize_dealer_or_admin, except: [:index, :show]
        
        # GET /api/b2b/dealer_discounts
        # Dealer kendi indirimlerini görebilir, admin hepsini görebilir
        def index
          @discounts = if current_user.admin?
            ::B2b::DealerDiscount.includes(:dealer, :product).all
          elsif current_user.dealer?
            current_user.dealer_discounts.includes(:product).active
          else
            return render json: { error: 'Unauthorized' }, status: :forbidden
          end
          
          render json: {
            data: @discounts.map { |discount| serialize_discount(discount) },
            meta: {
              total: @discounts.count
            }
          }
        end
        
        # GET /api/b2b/dealer_discounts/:id
        def show
          render json: { data: serialize_discount(@discount) }
        end
        
        # POST /api/b2b/dealer_discounts
        # Admin dealer'lara indirim tanımlayabilir
        def create
          dealer = User.dealer.find(params[:dealer_id])
          product = Catalog::Product.find(params[:product_id])
          
          @discount = ::B2b::DealerDiscount.new(
            dealer: dealer,
            product: product,
            discount_percent: params[:discount_percent],
            active: params[:active] || true
          )
          
          if @discount.save
            render json: {
              message: 'Dealer discount created successfully',
              data: serialize_discount(@discount)
            }, status: :created
          else
            render json: {
              error: 'Failed to create discount',
              details: @discount.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # PATCH /api/b2b/dealer_discounts/:id
        def update
          if @discount.update(discount_params)
            render json: {
              message: 'Discount updated successfully',
              data: serialize_discount(@discount)
            }
          else
            render json: {
              error: 'Failed to update discount',
              details: @discount.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # DELETE /api/b2b/dealer_discounts/:id
        def destroy
          @discount.destroy!
          render json: { message: 'Discount deleted successfully' }
        end
        
        # PATCH /api/b2b/dealer_discounts/:id/toggle_active
        def toggle_active
          @discount.toggle_active!
          render json: {
            message: "Discount #{@discount.active? ? 'activated' : 'deactivated'}",
            data: serialize_discount(@discount)
          }
        end
        
        private
        
        def set_discount
          @discount = if current_user.admin?
            ::B2b::DealerDiscount.find(params[:id])
          elsif current_user.dealer?
            current_user.dealer_discounts.find(params[:id])
          else
            return render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
        
        def authorize_dealer_or_admin
          unless current_user.admin? || current_user.dealer?
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
        
        def discount_params
          params.permit(:discount_percent, :active)
        end
        
        def serialize_discount(discount)
          {
            type: 'dealer_discounts',
            id: discount.id.to_s,
            attributes: {
              dealer_id: discount.dealer_id,
              dealer_name: discount.dealer.name,
              dealer_email: discount.dealer.email,
              product_id: discount.product_id,
              product_title: discount.product.title,
              product_sku: discount.product.sku,
              discount_percent: discount.discount_percent,
              formatted_discount: discount.formatted_discount,
              active: discount.active,
              created_at: discount.created_at,
              updated_at: discount.updated_at
            },
            relationships: {
              dealer: {
                data: { type: 'users', id: discount.dealer_id.to_s }
              },
              product: {
                data: { type: 'products', id: discount.product_id.to_s }
              }
            }
          }
        end
      end
    end
  end
end
