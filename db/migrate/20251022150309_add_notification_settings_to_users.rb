class AddNotificationSettingsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :email_notifications, :boolean, default: true
    add_column :users, :sms_notifications, :boolean, default: false
    add_column :users, :whatsapp_notifications, :boolean, default: true
    add_column :users, :phone, :string
    add_column :users, :address, :text
    add_column :users, :city, :string
    add_column :users, :company, :string
  end
end
