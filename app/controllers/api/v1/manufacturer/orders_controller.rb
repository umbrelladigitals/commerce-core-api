# frozen_string_literal: true

module Api
  module V1
    module Manufacturer
      class OrdersController < ApplicationController
        before_action :authenticate_user!
        before_action :require_manufacturer!
        before_action :set_order, only: [:show, :update_status]

        def index
          # Filtreleme parametreleri
          orders = orders_scope

          # Üretim durumuna göre filtreleme
          if params[:production_status].present?
            orders = orders.where(production_status: params[:production_status])
          end

          # Sipariş durumuna göre filtreleme
          if params[:status].present?
            orders = orders.where(status: params[:status])
          end

          # Müşteriye göre filtreleme
          if params[:customer_id].present?
            orders = orders.where(user_id: params[:customer_id])
          end

          # Tarih aralığı filtresi
          if params[:start_date].present?
            orders = orders.where('orders.created_at >= ?', params[:start_date])
          end

          if params[:end_date].present?
            orders = orders.where('orders.created_at <= ?', params[:end_date])
          end

          # Sayfalama
          page = params[:page] || 1
          per_page = params[:per_page] || 20

          orders = orders.page(page).per(per_page)
                        .includes(:user, :order_lines)
                        .order(created_at: :desc)

          # Serileştirme
          orders_data = orders.map { |order| serialize_order_list_item(order) }

          render json: {
            data: orders_data,
            meta: {
              current_page: orders.current_page,
              total_pages: orders.total_pages,
              total_count: orders.total_count,
              per_page: per_page.to_i
            }
          }, status: :ok
        end

        def show
          render json: {
            data: {
              type: 'order',
              id: @order.id.to_s,
              attributes: serialize_order_detail(@order)
            }
          }, status: :ok
        end

        def update_status
          new_status = params[:production_status]

          unless ::Orders::Order.production_statuses.key?(new_status)
            return render json: { error: 'Invalid production status' }, status: :unprocessable_entity
          end

          # Kargoya verirken shipment bilgileri zorunlu
          if new_status == 'shipped'
            shipment_params = params[:shipment]
            unless shipment_params && shipment_params[:carrier].present? && shipment_params[:tracking_number].present?
              return render json: { 
                error: 'Shipment information required',
                details: 'Carrier and tracking number are required when marking as shipped'
              }, status: :unprocessable_entity
            end
          end

          begin
            ActiveRecord::Base.transaction do
              @order.update_production_status!(new_status, current_user)

              # Shipment oluştur veya güncelle
              if new_status == 'shipped' && params[:shipment].present?
                shipment = @order.shipment || @order.build_shipment
                shipment.assign_attributes(
                  carrier: params[:shipment][:carrier],
                  tracking_number: params[:shipment][:tracking_number],
                  status: :in_transit,
                  notes: params[:shipment][:notes]
                )
                shipment.save!
              end
            end

            render json: {
              data: {
                type: 'order',
                id: @order.id.to_s,
                attributes: {
                  order_number: @order.order_number,
                  production_status: @order.production_status,
                  updated_at: @order.updated_at.iso8601,
                  shipment: @order.shipment ? {
                    carrier: @order.shipment.carrier,
                    tracking_number: @order.shipment.tracking_number,
                    status: @order.shipment.status
                  } : nil
                }
              },
              message: 'Production status updated successfully'
            }, status: :ok
          rescue StandardError => e
            render json: { error: e.message }, status: :unprocessable_entity
          end
        end

        private

        def orders_scope
          # Sadece ödeme alınmış siparişler üretim için geçerli
          ::Orders::Order.where(status: [:paid, :shipped])
                        .where.not(status: :cancelled)
        end

        def set_order
          @order = orders_scope.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Order not found' }, status: :not_found
        end

        def require_manufacturer!
          unless current_user&.manufacturer?
            render json: { error: 'Unauthorized - Manufacturer access required' }, status: :forbidden
          end
        end

        def serialize_order_list_item(order)
          {
            id: order.id,
            order_number: order.order_number,
            customer: {
              id: order.user&.id,
              name: order.user&.name || 'Guest',
              email: order.user&.email,
              phone: order.user&.phone
            },
            production_status: order.production_status,
            status: order.status,
            items_count: order.order_lines.sum(:quantity),
            order_lines: order.order_lines.includes(:product, :variant).map do |line|
              {
                id: line.id,
                product_name: line.product&.title,
                quantity: line.quantity,
                product_options: line.variant&.options&.map { |k, v| { option_name: k, value_name: v } } || []
              }
            end,
            total: format_money(order.total),
            created_at: order.created_at.iso8601,
            updated_at: order.updated_at.iso8601
          }
        end

        def serialize_order_detail(order)
          {
            order_number: order.order_number,
            status: order.status,
            production_status: order.production_status,
            customer: {
              id: order.user&.id,
              name: order.shipping_address&.dig('name') || order.user&.name || 'Guest',
              email: order.user&.email,
              phone: order.shipping_address&.dig('phone') || order.user&.phone,
              address: order.shipping_address&.dig('address_line1'),
              address_line2: order.shipping_address&.dig('address_line2'),
              city: order.shipping_address&.dig('city'),
              state: order.shipping_address&.dig('state'),
              zip_code: order.shipping_address&.dig('postal_code'),
              country: order.shipping_address&.dig('country')
            },
            order_lines: order.order_lines.includes(:product, :variant).map do |line|
              {
                id: line.id,
                product: {
                  id: line.product.id,
                  name: line.product.title,
                  sku: line.product.sku
                },
                variant: line.variant ? {
                  id: line.variant.id,
                  sku: line.variant.sku,
                  options: line.variant.options,
                  display_name: line.variant.display_name
                } : nil,
                quantity: line.quantity,
                unit_price: format_money(line.unit_price),
                subtotal: format_money(line.total)
              }
            end,
            subtotal: format_money(order.subtotal),
            shipping: format_money(order.shipping),
            tax: format_money(order.tax),
            discount: order.discount ? format_money(order.discount) : nil,
            total: format_money(order.total),
            notes: order.notes,
            created_at: order.created_at.iso8601,
            updated_at: order.updated_at.iso8601,
            status_logs: order.status_logs.includes(:user).order(created_at: :desc).limit(10).map do |log|
              {
                id: log.id,
                from_status: log.from_status,
                to_status: log.to_status,
                changed_by: log.user&.name,
                created_at: log.created_at.iso8601
              }
            end
          }
        end

        def format_money(amount)
          {
            amount: amount.cents,
            formatted: amount.format
          }
        end
      end
    end
  end
end
