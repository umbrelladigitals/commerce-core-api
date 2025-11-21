class CreateNotificationTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_templates do |t|
      t.string :name, null: false
      t.string :channel, null: false # email, sms, whatsapp
      t.string :subject
      t.text :body, null: false
      t.boolean :active, default: true

      t.timestamps
    end
    
    add_index :notification_templates, [:name, :channel], unique: true
    add_index :notification_templates, :channel
  end
end
