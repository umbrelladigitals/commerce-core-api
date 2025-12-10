class SeedDefaultSettings < ActiveRecord::Migration[7.1]
  def up
    settings = [
      { key: 'site_name', value: 'B2B Commerce', value_type: 'string', description: 'Site Adı' },
      { key: 'site_url', value: 'https://example.com', value_type: 'string', description: 'Site URL' },
      { key: 'contact_email', value: 'info@example.com', value_type: 'string', description: 'İletişim E-posta' },
      { key: 'smtp_host', value: 'smtp.example.com', value_type: 'string', description: 'SMTP Sunucusu' },
      { key: 'smtp_port', value: '587', value_type: 'integer', description: 'SMTP Portu' },
      { key: 'smtp_user', value: '', value_type: 'string', description: 'SMTP Kullanıcı Adı' },
      { key: 'smtp_pass', value: '', value_type: 'string', description: 'SMTP Şifre' },
      { key: 'security_2fa_required', value: 'false', value_type: 'boolean', description: '2FA Zorunluluğu' },
      { key: 'security_strong_password', value: 'true', value_type: 'boolean', description: 'Güçlü Şifre Politikası' }
    ]

    settings.each do |s|
      Setting.find_or_create_by(key: s[:key]) do |setting|
        setting.value = s[:value]
        setting.value_type = s[:value_type]
        setting.description = s[:description]
      end
    end
  end

  def down
    keys = %w[site_name site_url contact_email smtp_host smtp_port smtp_user smtp_pass security_2fa_required security_strong_password]
    Setting.where(key: keys).destroy_all
  end
end
