# frozen_string_literal: true

module Api
  module V1
    module Admin
      class UsersController < ApplicationController
        before_action :authenticate_user!
        before_action :require_admin!

        # GET /api/v1/admin/users
        def index
          users = User.order(created_at: :desc)

          # Role filter
          users = users.where(role: params[:role]) if params[:role].present?

          # Search
          if params[:search].present?
            search_term = "%#{params[:search]}%"
            users = users.where(
              'name ILIKE ? OR email ILIKE ?',
              search_term,
              search_term
            )
          end

          # Pagination
          page = params[:page] || 1
          users = users.page(page).per(params[:per_page] || 50)

          render json: {
            data: users.map { |user| serialize_user(user) },
            meta: {
              current_page: users.current_page,
              total_pages: users.total_pages,
              total_count: users.total_count
            }
          }
        end

        # GET /api/v1/admin/users/:id
        def show
          user = User.find(params[:id])

          render json: {
            data: serialize_user(user, include_details: true)
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Kullanıcı bulunamadı' }, status: :not_found
        end

        # PATCH /api/v1/admin/users/:id
        def update
          user = User.find(params[:id])

          if user.update(user_update_params)
            render json: {
              data: serialize_user(user),
              message: 'Kullanıcı güncellendi'
            }
          else
            render json: {
              errors: user.errors.full_messages
            }, status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Kullanıcı bulunamadı' }, status: :not_found
        end

        # POST /api/v1/admin/users
        def create
          user = User.new(user_create_params)

          if user.save
            render json: {
              data: serialize_user(user),
              message: 'Kullanıcı oluşturuldu'
            }, status: :created
          else
            render json: {
              error: 'Kullanıcı oluşturulamadı',
              errors: user.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/users/:id
        def destroy
          user = User.find(params[:id])

          if user.id == current_user.id
            return render json: {
              error: 'Kendi hesabınızı silemezsiniz'
            }, status: :unprocessable_entity
          end

          user.destroy
          render json: { message: 'Kullanıcı silindi' }
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Kullanıcı bulunamadı' }, status: :not_found
        end

        # POST /api/v1/admin/users/:id/add_balance
        def add_balance
          user = User.find(params[:id])

          unless user.dealer?
            return render json: {
              error: 'Bu kullanıcı bayi değil'
            }, status: :unprocessable_entity
          end

          amount = params[:amount].to_f
          currency = params[:currency] || 'USD'
          note = params[:note]

          if amount <= 0
            return render json: {
              error: 'Miktar 0\'dan büyük olmalı'
            }, status: :unprocessable_entity
          end

          user.ensure_dealer_balance!
          balance = user.dealer_balance

          # Bakiye işlemini gerçekleştir
          previous_balance = balance.balance_cents
          balance.balance_cents += (amount * 100).to_i
          balance.save!

          # İşlem kaydı oluştur
          transaction = balance.transactions.create!(
            amount_cents: (amount * 100).to_i,
            currency: currency,
            transaction_type: 'credit',
            description: note || "Admin tarafından eklenen bakiye",
            created_by_id: current_user.id
          )

          render json: {
            data: {
              balance: balance.balance_cents / 100.0,
              currency: balance.currency,
              previous_balance: previous_balance / 100.0,
              added_amount: amount,
              transaction_id: transaction.id
            },
            message: 'Bakiye eklendi'
          }
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Kullanıcı bulunamadı' }, status: :not_found
        end

        private

        def user_update_params
          params.require(:user).permit(:name, :email, :role, :active)
        end

        def user_create_params
          params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :phone, :company)
        end

        def serialize_user(user, include_details: false)
          data = {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            active: user.active,
            created_at: user.created_at,
            updated_at: user.updated_at
          }

          if include_details
            data[:order_count] = user.orders.count
            data[:total_spent] = user.orders.where(status: :paid).sum(:total_cents)
            
            # Bayi ise bakiye bilgisini ekle
            if user.dealer? && user.dealer_balance
              data[:balance] = {
                amount_cents: user.dealer_balance.balance_cents,
                amount: user.dealer_balance.balance_cents / 100.0,
                currency: user.dealer_balance.currency
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
