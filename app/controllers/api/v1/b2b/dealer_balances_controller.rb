# frozen_string_literal: true

module Api
  module V1
    module B2b
      # Dealer bakiye yönetimi controller'ı
      # Dealer kendi bakiyesini görebilir, admin tüm işlemleri yapabilir
      class DealerBalancesController < ApplicationController
        before_action :authenticate_user!
        before_action :set_balance, only: [:show, :add_credit, :update_credit_limit]
        before_action :authorize_admin, only: [:index, :add_credit, :update_credit_limit]
        
        # GET /api/b2b/dealer_balances
        # Admin tüm dealer bakiyelerini görebilir
        def index
          @balances = ::B2b::DealerBalance.includes(:dealer).all
          
          render json: {
            data: @balances.map { |balance| serialize_balance(balance) },
            meta: {
              total: @balances.count,
              total_balance_cents: @balances.sum(:balance_cents),
              positive_balances: @balances.with_positive_balance.count,
              negative_balances: @balances.with_negative_balance.count,
              over_limit: @balances.over_credit_limit.count
            }
          }
        end
        
        # GET /api/b2b/dealer_balances/:id
        # Dealer kendi bakiyesini, admin herkesi görebilir
        def show
          render json: {
            data: serialize_balance(@balance),
            meta: @balance.summary
          }
        end
        
        # POST /api/b2b/dealer_balances/:id/add_credit
        # Admin dealer bakiyesine para ekler (ödeme alındığında)
        def add_credit
          amount_cents = params[:amount_cents].to_i
          note = params[:note]
          
          if @balance.add_credit!(amount_cents, note: note)
            render json: {
              message: 'Credit added successfully',
              data: serialize_balance(@balance.reload),
              meta: @balance.summary
            }
          else
            render json: {
              error: 'Failed to add credit',
              details: @balance.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # PATCH /api/b2b/dealer_balances/:id/update_credit_limit
        # Admin dealer kredi limitini günceller
        def update_credit_limit
          new_limit_cents = params[:credit_limit_cents].to_i
          
          if @balance.update_credit_limit!(new_limit_cents)
            render json: {
              message: 'Credit limit updated successfully',
              data: serialize_balance(@balance.reload),
              meta: @balance.summary
            }
          else
            render json: {
              error: 'Failed to update credit limit',
              details: @balance.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # GET /api/b2b/my_balance
        # Dealer kendi bakiyesini görür
        def my_balance
          unless current_user.dealer?
            return render json: { error: 'Only dealers can view their balance' }, status: :forbidden
          end
          
          balance = current_user.dealer_balance || current_user.ensure_dealer_balance!
          
          render json: {
            data: serialize_balance(balance),
            meta: balance.summary
          }
        end
        
        private
        
        def set_balance
          @balance = if current_user.admin?
            ::B2b::DealerBalance.find(params[:id])
          elsif current_user.dealer?
            current_user.dealer_balance || current_user.ensure_dealer_balance!
          else
            return render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
        
        def authorize_admin
          unless current_user.admin?
            render json: { error: 'Admin access required' }, status: :forbidden
          end
        end
        
        def serialize_balance(balance)
          {
            type: 'dealer_balances',
            id: balance.id.to_s,
            attributes: {
              dealer_id: balance.dealer_id,
              dealer_name: balance.dealer.name,
              dealer_email: balance.dealer.email,
              balance: balance.balance.format,
              balance_cents: balance.balance_cents,
              credit_limit: balance.credit_limit.format,
              credit_limit_cents: balance.credit_limit_cents,
              available_balance: balance.available_balance.format,
              available_balance_cents: balance.available_balance_cents,
              currency: balance.currency,
              status: balance.balance_status,
              positive_balance: balance.positive_balance?,
              negative_balance: balance.negative_balance?,
              over_limit: balance.over_limit?,
              debt: balance.debt_amount.format,
              debt_cents: balance.debt_amount_cents,
              last_transaction_at: balance.last_transaction_at,
              created_at: balance.created_at,
              updated_at: balance.updated_at
            },
            relationships: {
              dealer: {
                data: { type: 'users', id: balance.dealer_id.to_s }
              }
            }
          }
        end
      end
    end
  end
end
