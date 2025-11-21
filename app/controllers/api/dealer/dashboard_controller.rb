# frozen_string_literal: true

module Api
  module Dealer
    # Bayi dashboard ve işlemleri
    # Bayilerin kendi bilgilerini görüntülemesi ve yönetmesi için endpoint'ler
    class DashboardController < ApplicationController
      before_action :authenticate_user!
      before_action :ensure_dealer_role
      before_action :find_or_create_balance, only: [:dashboard, :balance, :topup, :balance_history]
      
      # GET /api/dealer/dashboard
      # Bayi genel dashboard bilgileri
      def dashboard
        # Son siparişler
        recent_orders = current_user.orders
                                   .where.not(status: :cart)
                                   .order(created_at: :desc)
                                   .limit(5)
        
        # İstatistikler
        total_orders = current_user.orders.where.not(status: :cart).count
        total_spent = current_user.orders.paid.sum(:total_cents)
        pending_orders = current_user.orders.paid.count
        
        # Aktif iskontolar
        active_discounts = B2b::DealerDiscount.active
                                              .for_dealer(current_user.id)
                                              .includes(:product)
                                              .limit(5)
        
        render json: {
          data: {
            type: 'dealer_dashboard',
            attributes: {
              dealer_info: {
                name: current_user.name,
                email: current_user.email,
                role: current_user.role
              },
              balance: {
                current: @balance.balance.format,
                current_cents: @balance.balance_cents,
                credit_limit: @balance.credit_limit.format,
                credit_limit_cents: @balance.credit_limit_cents,
                available: @balance.available_balance.format,
                available_cents: @balance.available_balance_cents
              },
              statistics: {
                total_orders: total_orders,
                total_spent: Money.new(total_spent, 'USD').format,
                pending_orders: pending_orders,
                active_discounts_count: active_discounts.count
              },
              recent_orders: recent_orders.map do |order|
                {
                  id: order.id,
                  order_number: order.order_number,
                  status: order.status,
                  total: order.total.format,
                  created_at: order.created_at,
                  items_count: order.order_lines.count
                }
              end,
              active_discounts: active_discounts.map do |discount|
                {
                  id: discount.id,
                  product_id: discount.product_id,
                  product_name: discount.product.title,
                  discount_percent: discount.discount_percent,
                  active: discount.active
                }
              end
            }
          }
        }, status: :ok
      end
      
      # GET /api/dealer/orders
      # Bayi siparişleri (filtrelenebilir)
      def orders
        orders = current_user.orders
                            .where.not(status: :cart)
                            .includes(:order_lines)
                            .order(created_at: :desc)
        
        # Filtreleme
        orders = orders.where(status: params[:status]) if params[:status].present?
        
        if params[:start_date].present?
          start_date = Date.parse(params[:start_date])
          orders = orders.where('created_at >= ?', start_date.beginning_of_day)
        end
        
        if params[:end_date].present?
          end_date = Date.parse(params[:end_date])
          orders = orders.where('created_at <= ?', end_date.end_of_day)
        end
        
        # Sayfalama
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 20
        per_page = [per_page, 100].min # Max 100
        
        paginated_orders = orders.page(page).per(per_page)
        
        render json: {
          data: paginated_orders.map do |order|
            {
              type: 'orders',
              id: order.id.to_s,
              attributes: {
                order_number: order.order_number,
                status: order.status,
                total: order.total.format,
                total_cents: order.total_cents,
                subtotal: order.subtotal.format,
                shipping: order.shipping.format,
                tax: order.tax.format,
                items_count: order.order_lines.count,
                paid_at: order.paid_at,
                created_at: order.created_at,
                items: order.order_lines.map do |line|
                  {
                    product_id: line.product_id,
                    product_title: line.product_title,
                    quantity: line.quantity,
                    unit_price: line.unit_price.format,
                    total: line.total.format
                  }
                end
              }
            }
          end,
          meta: {
            current_page: paginated_orders.current_page,
            total_pages: paginated_orders.total_pages,
            total_count: paginated_orders.total_count,
            per_page: per_page
          }
        }, status: :ok
      end
      
      # GET /api/dealer/discounts
      # Bayi özel iskontoları
      def discounts
        discounts = B2b::DealerDiscount.for_dealer(current_user.id)
                                       .includes(:product)
                                       .order(created_at: :desc)
        
        # Filtreleme
        discounts = discounts.active if params[:active] == 'true'
        discounts = discounts.for_product(params[:product_id]) if params[:product_id].present?
        
        render json: {
          data: discounts.map do |discount|
            {
              type: 'dealer_discounts',
              id: discount.id.to_s,
              attributes: {
                product_id: discount.product_id,
                product_slug: discount.product.slug,
                product_name: discount.product.title,
                product_sku: discount.product.sku,
                discount_percent: discount.discount_percent,
                active: discount.active,
                created_at: discount.created_at,
                example_calculation: {
                  original_price: discount.product.price.format,
                  discounted_price: Money.new(
                    discount.calculate_discounted_price(discount.product.price_cents),
                    discount.product.currency
                  ).format,
                  savings: Money.new(
                    discount.product.price_cents - discount.calculate_discounted_price(discount.product.price_cents),
                    discount.product.currency
                  ).format
                }
              }
            }
          end
        }, status: :ok
      end
      
      # GET /api/dealer/balance
      # Bayi bakiye bilgileri
      def balance
        render json: {
          data: {
            type: 'dealer_balance',
            id: @balance.id.to_s,
            attributes: {
              balance: @balance.balance.format,
              balance_cents: @balance.balance_cents,
              credit_limit: @balance.credit_limit.format,
              credit_limit_cents: @balance.credit_limit_cents,
              available_balance: @balance.available_balance.format,
              available_balance_cents: @balance.available_balance_cents,
              currency: @balance.currency,
              last_transaction_at: @balance.last_transaction_at
            }
          }
        }, status: :ok
      end
      
      # GET /api/dealer/balance/history
      # Bakiye işlem geçmişi
      def balance_history
        transactions = @balance.transactions
                              .recent
                              .includes(:order)
        
        # Filtreleme
        if params[:transaction_type].present?
          transactions = transactions.where(transaction_type: params[:transaction_type])
        end
        
        if params[:start_date].present?
          start_date = Date.parse(params[:start_date])
          transactions = transactions.where('created_at >= ?', start_date.beginning_of_day)
        end
        
        # Limit (basit sayfalama yerine)
        limit = params[:limit]&.to_i || 50
        limit = [limit, 100].min
        
        limited_transactions = transactions.limit(limit)
        
        render json: {
          data: limited_transactions.map do |transaction|
            {
              type: 'balance_transactions',
              id: transaction.id.to_s,
              attributes: {
                transaction_type: transaction.transaction_type,
                type_label: transaction.type_label,
                amount: transaction.amount.format,
                amount_cents: transaction.amount_cents,
                positive: transaction.positive?,
                note: transaction.note,
                order_id: transaction.order_id,
                order_number: transaction.order&.order_number,
                created_at: transaction.created_at
              }
            }
          end,
          meta: {
            total_count: limited_transactions.count,
            limit: limit,
            current_balance: @balance.balance.format
          }
        }, status: :ok
      end
      
      # POST /api/dealer/balance/topup
      # Manuel bakiye yükleme (gerçek uygulamada ödeme entegrasyonu gerekir)
      def topup
        amount_cents = params[:amount_cents]&.to_i
        
        unless amount_cents && amount_cents > 0
          return render json: {
            error: 'Geçersiz tutar',
            details: 'amount_cents pozitif bir sayı olmalıdır'
          }, status: :unprocessable_entity
        end
        
        # Maksimum yükleme limiti (opsiyonel)
        max_topup = 1_000_000 # 10,000 USD
        if amount_cents > max_topup
          return render json: {
            error: 'Maksimum yükleme limitini aştınız',
            details: "Maksimum #{Money.new(max_topup, 'USD').format} yüklenebilir"
          }, status: :unprocessable_entity
        end
        
        note = params[:note] || "Manuel bakiye yükleme - #{Time.current.strftime('%d/%m/%Y %H:%M')}"
        
        if @balance.topup!(amount_cents, note: note)
          render json: {
            message: 'Bakiye başarıyla yüklendi',
            data: {
              type: 'dealer_balance',
              attributes: {
                balance: @balance.balance.format,
                balance_cents: @balance.balance_cents,
                available_balance: @balance.available_balance.format,
                loaded_amount: Money.new(amount_cents, @balance.currency).format,
                loaded_amount_cents: amount_cents
              }
            }
          }, status: :ok
        else
          render json: {
            error: 'Bakiye yüklenemedi',
            details: @balance.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def ensure_dealer_role
        unless current_user.dealer?
          render json: {
            error: 'Yetkisiz erişim',
            message: 'Bu endpoint sadece bayiler için erişilebilir'
          }, status: :forbidden
        end
      end
      
      def find_or_create_balance
        @balance = B2b::DealerBalance.find_or_create_by!(dealer: current_user)
      end
    end
  end
end
