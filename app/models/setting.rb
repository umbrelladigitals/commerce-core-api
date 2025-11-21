class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value_type, inclusion: { in: %w[string integer float boolean json] }
  
  # Cache settings in memory for performance
  class << self
    def get(key, default = nil)
      setting = Rails.cache.fetch("setting:#{key}", expires_in: 1.hour) do
        find_by(key: key)
      end
      
      return default unless setting
      
      case setting.value_type
      when 'integer'
        setting.value.to_i
      when 'float'
        setting.value.to_f
      when 'boolean'
        setting.value.to_s.downcase.in?(%w[true 1 yes])
      when 'json'
        JSON.parse(setting.value)
      else
        setting.value
      end
    rescue => e
      Rails.logger.error "Setting.get error for key '#{key}': #{e.message}"
      default
    end
    
    def set(key, value, description: nil, value_type: 'string')
      setting = find_or_initialize_by(key: key)
      setting.value = value.to_s
      setting.description = description if description
      setting.value_type = value_type
      setting.save!
      
      # Clear cache
      Rails.cache.delete("setting:#{key}")
      
      setting
    end
    
    def tax_rate
      get('tax_rate', 0.20)
    end
    
    def free_shipping_threshold
      get('free_shipping_threshold', 500.0)
    end
    
    def default_shipping_cost
      get('default_shipping_cost', 30.0)
    end
    
    # IBAN / Banka Hesapları
    def bank_accounts
      accounts = get('bank_accounts', '[]')
      accounts.is_a?(String) ? JSON.parse(accounts) : accounts
    rescue JSON::ParserError
      []
    end
    
    def set_bank_accounts(accounts_array)
      set('bank_accounts', accounts_array.to_json, 
          description: 'Havale/EFT için banka hesap bilgileri',
          value_type: 'json')
    end
  end
end
