# frozen_string_literal: true

module Api
  module V1
    module Marketer
      # Pazarlamacı için müşteri arama ve listesi
      class CustomersController < ApplicationController
        before_action :authenticate_user!
        before_action :require_marketer!

        # GET /api/v1/marketer/customers
        def index
          customers = User.where(role: [:customer, :dealer])
          
          # Arama
          if params[:search].present?
            search_term = "%#{params[:search].downcase}%"
            customers = customers.where(
              'LOWER(name) LIKE ? OR LOWER(email) LIKE ? OR LOWER(phone) LIKE ?',
              search_term, search_term, search_term
            )
          end
          
          # Role filtresi
          if params[:role].present? && ['customer', 'dealer'].include?(params[:role])
            customers = customers.where(role: params[:role])
          end
          
          # Sayfalama
          page = params[:page].to_i.positive? ? params[:page].to_i : 1
          per_page = [params[:per_page].to_i, 50].min
          per_page = 20 if per_page.zero?
          
          customers = customers.order(:name).page(page).per(per_page)
          
          render json: {
            data: customers.map { |customer| serialize_customer(customer) },
            meta: {
              current_page: customers.current_page,
              total_pages: customers.total_pages,
              total_count: customers.total_count,
              per_page: per_page
            }
          }, status: :ok
        end

        # GET /api/v1/marketer/customers/:id
        def show
          customer = User.find(params[:id])
          
          unless customer.customer? || customer.dealer?
            return render json: { error: 'Bu kullanıcı müşteri değil' }, status: :bad_request
          end
          
          # Müşterinin sipariş geçmişi
          orders = customer.orders.where.not(status: :cart)
                          .order(created_at: :desc)
                          .limit(10)
          
          render json: {
            data: {
              type: 'customer',
              id: customer.id.to_s,
              attributes: serialize_customer_detail(customer),
              relationships: {
                recent_orders: orders.map do |order|
                  {
                    id: order.id,
                    order_number: order.id.to_s.rjust(6, '0'),
                    status: order.status,
                    total: format_money(order.total_cents),
                    created_at: order.created_at.iso8601
                  }
                end
              }
            }
          }, status: :ok
        end

        # POST /api/v1/marketer/customers
        # Yeni müşteri oluştur
        def create
          user = User.new(customer_params)
          user.role = params[:role] || :customer
          user.password = params[:password] || SecureRandom.hex(8)
          user.password_confirmation = user.password

          if user.save
            render json: {
              data: {
                type: 'customer',
                id: user.id.to_s,
                attributes: serialize_customer(user)
              },
              message: 'Müşteri başarıyla oluşturuldu'
            }, status: :created
          else
            render json: {
              error: 'Müşteri oluşturulamadı',
              details: user.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def require_marketer!
          unless current_user&.marketer?
            render json: { error: 'Bu işlem için pazarlamacı yetkisi gereklidir' }, status: :forbidden
          end
        end

        def serialize_customer(customer)
          {
            id: customer.id,
            name: customer.name,
            email: customer.email,
            phone: customer.phone,
            role: customer.role,
            role_label: role_label(customer.role),
            created_at: customer.created_at.iso8601
          }
        end

        def serialize_customer_detail(customer)
          {
            id: customer.id,
            name: customer.name,
            email: customer.email,
            phone: customer.phone,
            role: customer.role,
            role_label: role_label(customer.role),
            address: customer.address,
            city: customer.city,
            created_at: customer.created_at.iso8601
          }
        end

        def role_label(role)
          case role
          when 'customer' then 'Müşteri'
          when 'dealer' then 'Bayi'
          else role
          end
        end

        def format_money(cents)
          "$#{'%.2f' % (cents / 100.0)}"
        end

        def customer_params
          params.require(:customer).permit(:name, :email, :phone, :address, :city, :state, :zip_code, :country, :company)
        end
      end
    end
  end
end
