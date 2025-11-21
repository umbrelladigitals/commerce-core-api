module Api
  module V1
    class BankAccountsController < ApplicationController
      # GET /api/v1/bank_accounts
      # Public endpoint - ödeme sayfasında gösterilecek
      def index
        accounts = Setting.bank_accounts
        
        # Sadece gerekli bilgileri döndür
        public_accounts = accounts.map do |account|
          {
            id: account['id'] || account[:id],
            bank_name: account['bank_name'] || account[:bank_name],
            iban: format_iban(account['iban'] || account[:iban]),
            account_holder: account['account_holder'] || account[:account_holder],
            branch: account['branch'] || account[:branch]
          }
        end
        
        render json: {
          data: {
            type: 'bank_accounts',
            attributes: {
              accounts: public_accounts
            }
          }
        }
      end

      private

      def format_iban(iban)
        return '' if iban.blank?
        
        # Format: TR00 0000 0000 0000 0000 0000 00
        iban_clean = iban.gsub(/\s+/, '')
        iban_clean.scan(/.{1,4}/).join(' ')
      end
    end
  end
end
