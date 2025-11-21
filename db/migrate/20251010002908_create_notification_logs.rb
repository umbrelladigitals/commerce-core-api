class CreateNotificationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_logs do |t|
      t.string :recipient, null: false
      t.string :channel, null: false # email, sms, whatsapp
      t.jsonb :payload, default: {}
      t.string :status, null: false # pending, sent, failed, delivered
      t.string :error_message
      t.references :notification_template, foreign_key: true
      t.references :user, foreign_key: true
      t.datetime :sent_at

      t.timestamps
    end
    
    add_index :notification_logs, :status
    add_index :notification_logs, :channel
    add_index :notification_logs, :created_at
  end
end
