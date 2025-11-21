class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :settings do |t|
      t.string :key, null: false, index: { unique: true }
      t.text :value
      t.string :description
      t.string :value_type, default: 'string'

      t.timestamps
    end
    
    # Varsayılan ayarları ekle
    reversible do |dir|
      dir.up do
        Setting.create!(
          key: 'tax_rate',
          value: '0.20',
          description: 'KDV oranı (0.20 = %20)',
          value_type: 'float'
        )
        
        Setting.create!(
          key: 'free_shipping_threshold',
          value: '500.0',
          description: 'Ücretsiz kargo için minimum sepet tutarı (TL)',
          value_type: 'float'
        )
        
        Setting.create!(
          key: 'default_shipping_cost',
          value: '30.0',
          description: 'Varsayılan kargo ücreti (TL)',
          value_type: 'float'
        )
      end
    end
  end
end
