# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Admin sipariş yönetimi
      # Yöneticiler müşteri/bayi adına sipariş oluşturabilir
      class OrdersController < ApplicationController
        before_action :authenticate_user!
        before_action :require_admin!
        
        # POST /api/v1/admin/orders
        # Müşteri veya bayi adına sipariş oluştur
        def create
          user = User.find(params[:user_id])
          
          ActiveRecord::Base.transaction do
            # Sipariş oluştur
        @order = ::Orders::Order.create!(
              user: user,
              status: params[:status] || :cart,
              currency: params[:currency] || 'USD'
            )
            
            # Sipariş satırlarını ekle
            if params[:order_lines].present?
              params[:order_lines].each do |line_params|
                product = ::Catalog::Product.find(line_params[:product_id])
                variant = line_params[:variant_id].present? ? ::Catalog::Variant.find(line_params[:variant_id]) : nil
                
                @order.order_lines.create!(
                  product: product,
                  variant: variant,
                  quantity: line_params[:quantity] || 1,
                  note: line_params[:note]
                )
              end
            end
            
            # Fiyatları hesapla
            ::Orders::OrderPriceCalculator.new(@order).calculate!
            
            # Admin notu ekle
            if params[:admin_note].present?
              @order.admin_notes.create!(
                note: params[:admin_note],
                author: current_user
              )
            end
            
            render json: {
              message: 'Sipariş başarıyla oluşturuldu',
              data: serialize_order(@order)
            }, status: :created
          end
          
        rescue ActiveRecord::RecordNotFound => e
          render json: {
            error: 'Kayıt bulunamadı',
            details: e.message
          }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: {
            error: 'Sipariş oluşturulamadı',
            details: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end
        
        # GET /api/v1/admin/orders
        # Tüm siparişleri listele (filtreleme ile)
        def index
          @orders = ::Orders::Order.includes(:user, order_lines: [:product, :variant]).order(created_at: :desc)
          
          # Filtreleme
          @orders = @orders.where(user_id: params[:user_id]) if params[:user_id].present?
          @orders = @orders.where(status: params[:status]) if params[:status].present?
          
          if params[:start_date].present?
            @orders = @orders.where('created_at >= ?', Date.parse(params[:start_date]).beginning_of_day)
          end
          
          if params[:end_date].present?
            @orders = @orders.where('created_at <= ?', Date.parse(params[:end_date]).end_of_day)
          end
          
          # Sayfalama
          page = params[:page] || 1
          @orders = @orders.page(page).per(20)
          
          render json: {
            data: @orders.map { |order| serialize_order(order) },
            meta: {
              current_page: @orders.current_page,
              total_pages: @orders.total_pages,
              total_count: @orders.total_count
            }
          }
        end
        
        # GET /api/v1/admin/orders/:id
        def show
          @order = ::Orders::Order.includes(:user, order_lines: [:product, :variant], admin_notes: :author).find(params[:id])
          
          render json: {
            data: serialize_order(@order, include_notes: true)
          }
        end
        
        # PATCH /api/v1/admin/orders/:id
        # Sipariş durumunu güncelle
        def update
          @order = ::Orders::Order.find(params[:id])
          
          if @order.update(order_update_params)
            # Durum değişikliği için not ekle
            if params[:admin_note].present?
              @order.admin_notes.create!(
                note: params[:admin_note],
                author: current_user
              )
            end
            
            render json: {
              message: 'Sipariş güncellendi',
              data: serialize_order(@order)
            }
          else
            render json: {
              error: 'Sipariş güncellenemedi',
              details: @order.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # DELETE /api/v1/admin/orders/:id
        # Siparişi iptal et (sadece cart durumunda)
        def destroy
          @order = ::Orders::Order.find(params[:id])
          
          unless @order.cart?
            return render json: {
              error: 'Sadece sepet durumundaki siparişler silinebilir'
            }, status: :unprocessable_entity
          end
          
          @order.destroy
          render json: { message: 'Sipariş silindi' }
        end
        
        private
        
        def order_update_params
          params.require(:order).permit(:status)
        end
        
        def serialize_order(order, include_notes: false)
          data = {
            id: order.id,
            order_number: order.order_number,
            status: order.status,
            total: order.total.format,
            subtotal: order.subtotal.format,
            tax: order.tax.format,
            shipping: order.shipping.format,
            currency: order.currency,
            items_count: order.order_lines.count,
            total_quantity: order.total_items,
            paid_at: order.paid_at,
            created_at: order.created_at,
            updated_at: order.updated_at
          }
          
          # User bilgisi varsa ekle
          if order.user.present?
            data[:user] = {
              id: order.user.id,
              name: order.user.name,
              email: order.user.email,
              role: order.user.role
            }
          else
            data[:user] = nil
          end
          
          # Order lines ekle
          if order.order_lines.loaded?
            data[:order_lines] = order.order_lines.map do |line|
              line_data = {
                id: line.id,
                product_name: line.product.title,
                quantity: line.quantity,
                price: line.unit_price.format,
                total: line.total.format
              }
              
              # Variant özellikleri varsa ekle
              if line.variant&.options.present?
                line_data[:product_options] = line.variant.options.map do |key, value|
                  {
                    option_name: key,
                    value_name: value
                  }
                end
              end
              
              line_data
            end
          end
          
          if include_notes && order.admin_notes.loaded?
            data[:admin_notes] = order.admin_notes.recent.map do |note|
              {
                id: note.id,
                note: note.note,
                author_name: note.author.name,
                created_at: note.created_at
              }
            end
          end
          
          data
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
