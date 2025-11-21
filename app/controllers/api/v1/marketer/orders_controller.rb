# frozen_string_literal: true

module Api
  module V1
    module Marketer
      # Pazarlamacı sipariş oluşturma
      # Müşteri/bayi adına sipariş toplayabilir
      class OrdersController < ApplicationController
        before_action :authenticate_user!
        before_action :require_marketer!

        # GET /api/v1/marketer/orders
        # Pazarlamacının oluşturduğu siparişleri listele
        def index
          orders = ::Orders::Order.where(created_by_marketer_id: current_user.id)
          
          # Status filtresi
          orders = orders.where(status: params[:status]) if params[:status].present?
          
          # Müşteri filtresi
          orders = orders.where(user_id: params[:customer_id]) if params[:customer_id].present?
          
          # Tarih filtresi
          if params[:start_date].present?
            orders = orders.where('created_at >= ?', Date.parse(params[:start_date]))
          end
          
          if params[:end_date].present?
            orders = orders.where('created_at <= ?', Date.parse(params[:end_date]).end_of_day)
          end
          
          # Sayfalama
          page = params[:page].to_i.positive? ? params[:page].to_i : 1
          per_page = [params[:per_page].to_i, 100].min
          per_page = 20 if per_page.zero?
          
          orders = orders.includes(:user, :order_lines)
                        .order(created_at: :desc)
                        .page(page)
                        .per(per_page)

          render json: {
            data: orders.map { |order| serialize_order(order) },
            meta: {
              current_page: orders.current_page,
              total_pages: orders.total_pages,
              total_count: orders.total_count,
              per_page: per_page
            }
          }, status: :ok
        end

        # GET /api/v1/marketer/orders/:id
        def show
          order = ::Orders::Order.find(params[:id])
          
          # Sadece kendi oluşturduğu siparişleri görebilir
          unless order.created_by_marketer_id == current_user.id
            return render json: { error: 'Bu siparişi görüntüleme yetkiniz yok' }, status: :forbidden
          end
          
          render json: {
            data: serialize_order_detail(order)
          }, status: :ok
        end

        # POST /api/v1/marketer/orders
        # Müşteri/bayi adına sipariş oluştur
        def create
          customer = User.find(params[:customer_id])
          
          unless customer.customer? || customer.dealer?
            return render json: { 
              error: 'Geçersiz müşteri. Sadece customer veya dealer rolündeki kullanıcılar için sipariş oluşturabilirsiniz.' 
            }, status: :bad_request
          end
          
          if params[:order_lines].blank? || params[:order_lines].empty?
            return render json: { error: 'Sipariş satırları gereklidir' }, status: :bad_request
          end

          ActiveRecord::Base.transaction do
            # Sipariş oluştur
            @order = ::Orders::Order.create!(
              user: customer,
              created_by_marketer_id: current_user.id,
              status: :pending,
              currency: params[:currency] || 'USD',
              notes: params[:notes]
            )

            # Sipariş satırlarını ekle
            params[:order_lines].each do |line_params|
              product = ::Catalog::Product.find(line_params[:product_id])
              variant = line_params[:variant_id].present? ? 
                       ::Catalog::Variant.find(line_params[:variant_id]) : nil

              price = variant&.price || product.price
              
              order_line = @order.order_lines.create!(
                product: product,
                variant: variant,
                quantity: line_params[:quantity].to_i,
                price: price,
                currency: @order.currency
              )

              # Ürün seçenekleri (product options)
              if line_params[:options].present?
                line_params[:options].each do |opt|
                  option = ::ProductOption.find_by(id: opt[:product_option_id])
                  value = ::ProductOptionValue.find_by(id: opt[:product_option_value_id])
                  
                  if option && value
                    ::Orders::OrderLineOption.create!(
                      order_line: order_line,
                      product_option: option,
                      product_option_value: value,
                      option_price: value.price || 0
                    )
                  end
                end
              end
            end

            # Fiyat hesapla
            calculator = ::Orders::Services::OrderPriceCalculator.new(@order)
            calculator.calculate

            render json: {
              data: serialize_order_detail(@order),
              message: 'Sipariş başarıyla oluşturuldu'
            }, status: :created
          end

        rescue ActiveRecord::RecordNotFound => e
          render json: { error: "Kayıt bulunamadı: #{e.message}" }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message, details: e.record.errors.full_messages }, status: :unprocessable_entity
        rescue StandardError => e
          render json: { error: "Sipariş oluşturulamadı: #{e.message}" }, status: :internal_server_error
        end

        private

        def require_marketer!
          unless current_user&.marketer?
            render json: { error: 'Bu işlem için pazarlamacı yetkisi gereklidir' }, status: :forbidden
          end
        end

        def serialize_order(order)
          {
            id: order.id,
            order_number: order.id.to_s.rjust(6, '0'),
            customer: {
              id: order.user.id,
              name: order.user.name,
              email: order.user.email,
              role: order.user.role
            },
            status: order.status,
            status_label: status_label(order.status),
            total: format_money(order.total_cents),
            items_count: order.order_lines.count,
            notes: order.notes,
            created_at: order.created_at.iso8601,
            updated_at: order.updated_at.iso8601
          }
        end

        def serialize_order_detail(order)
          {
            type: 'order',
            id: order.id.to_s,
            attributes: {
              order_number: order.id.to_s.rjust(6, '0'),
              status: order.status,
              status_label: status_label(order.status),
              subtotal: format_money(order.subtotal_cents),
              shipping_cost: format_money(order.shipping_cost_cents),
              tax: format_money(order.tax_cents),
              total: format_money(order.total_cents),
              currency: order.currency,
              notes: order.notes,
              created_at: order.created_at.iso8601,
              updated_at: order.updated_at.iso8601
            },
            relationships: {
              customer: {
                id: order.user.id,
                name: order.user.name,
                email: order.user.email,
                phone: order.user.phone,
                role: order.user.role
              },
              order_lines: order.order_lines.map do |line|
                {
                  id: line.id,
                  product_name: line.product.name,
                  variant_name: line.variant&.name,
                  sku: line.variant&.sku || line.product.sku,
                  quantity: line.quantity,
                  price: format_money(line.price_cents),
                  subtotal: format_money(line.subtotal_cents),
                  options: line.order_line_options.map do |opt|
                    {
                      option_name: opt.product_option.name,
                      value_name: opt.product_option_value.value,
                      price: format_money(opt.option_price_cents)
                    }
                  end
                }
              end
            }
          }
        end

        def status_label(status)
          {
            'cart' => 'Sepet',
            'pending' => 'Beklemede',
            'paid' => 'Ödendi',
            'processing' => 'Hazırlanıyor',
            'shipped' => 'Kargoya Verildi',
            'delivered' => 'Teslim Edildi',
            'cancelled' => 'İptal',
            'refunded' => 'İade'
          }[status] || status
        end

        def format_money(cents)
          "$#{'%.2f' % (cents / 100.0)}"
        end
      end
    end
  end
end
