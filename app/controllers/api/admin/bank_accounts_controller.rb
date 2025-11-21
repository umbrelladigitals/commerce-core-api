module Api
  module Admin
    class BankAccountsController < ApplicationController
      before_action :authenticate_user!
      before_action :ensure_admin

      # GET /api/admin/bank_accounts
      def index
        accounts = Setting.bank_accounts
        
        render json: {
          data: {
            type: 'bank_accounts',
            attributes: {
              accounts: accounts
            }
          }
        }
      end

      # POST /api/admin/bank_accounts
      def create
        accounts = Setting.bank_accounts
        new_account = {
          id: SecureRandom.uuid,
          bank_name: params[:bank_name],
          iban: params[:iban],
          account_holder: params[:account_holder],
          branch: params[:branch],
          account_number: params[:account_number]
        }

        # IBAN validation
        if new_account[:iban].blank?
          return render json: { error: 'IBAN zorunludur' }, status: :unprocessable_entity
        end

        # Format IBAN (remove spaces)
        new_account[:iban] = new_account[:iban].gsub(/\s+/, '').upcase

        # Basic TR IBAN validation
        unless new_account[:iban].match?(/^TR\d{24}$/)
          return render json: { error: 'Geçersiz IBAN formatı. TR ile başlamalı ve 26 karakter olmalıdır.' }, status: :unprocessable_entity
        end

        accounts << new_account
        Setting.set_bank_accounts(accounts)

        render json: {
          data: {
            type: 'bank_account',
            id: new_account[:id],
            attributes: new_account
          }
        }, status: :created
      end

      # PUT /api/admin/bank_accounts/:id
      def update
        accounts = Setting.bank_accounts
        account = accounts.find { |a| a['id'] == params[:id] || a[:id] == params[:id] }

        unless account
          return render json: { error: 'Banka hesabı bulunamadı' }, status: :not_found
        end

        account['bank_name'] = params[:bank_name] if params[:bank_name]
        account['account_holder'] = params[:account_holder] if params[:account_holder]
        account['branch'] = params[:branch] if params[:branch]
        account['account_number'] = params[:account_number] if params[:account_number]
        
        if params[:iban]
          iban = params[:iban].gsub(/\s+/, '').upcase
          unless iban.match?(/^TR\d{24}$/)
            return render json: { error: 'Geçersiz IBAN formatı' }, status: :unprocessable_entity
          end
          account['iban'] = iban
        end

        Setting.set_bank_accounts(accounts)

        render json: {
          data: {
            type: 'bank_account',
            id: account['id'] || account[:id],
            attributes: account
          }
        }
      end

      # DELETE /api/admin/bank_accounts/:id
      def destroy
        accounts = Setting.bank_accounts
        initial_count = accounts.size
        
        accounts.reject! { |a| a['id'] == params[:id] || a[:id] == params[:id] }
        
        if accounts.size == initial_count
          return render json: { error: 'Banka hesabı bulunamadı' }, status: :not_found
        end

        Setting.set_bank_accounts(accounts)

        head :no_content
      end

      private

      def ensure_admin
        unless current_user&.admin?
          render json: { error: 'Bu işlem için yetkiniz yok' }, status: :forbidden
        end
      end
    end
  end
end
