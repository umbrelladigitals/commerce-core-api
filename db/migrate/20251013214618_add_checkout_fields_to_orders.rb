class AddCheckoutFieldsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :payment_method, :string unless column_exists?(:orders, :payment_method)
    add_column :orders, :payment_status, :string, default: 'pending' unless column_exists?(:orders, :payment_status)
    add_column :orders, :shipping_address, :jsonb, default: {} unless column_exists?(:orders, :shipping_address)
    add_column :orders, :billing_address, :jsonb, default: {} unless column_exists?(:orders, :billing_address)
    add_column :orders, :notes, :text unless column_exists?(:orders, :notes)
    add_column :orders, :metadata, :jsonb, default: {} unless column_exists?(:orders, :metadata)
    add_column :orders, :paid_at, :datetime unless column_exists?(:orders, :paid_at)
    add_column :orders, :shipped_at, :datetime unless column_exists?(:orders, :shipped_at)
    add_column :orders, :cancelled_at, :datetime unless column_exists?(:orders, :cancelled_at)
    
    add_index :orders, :payment_method unless index_exists?(:orders, :payment_method)
    add_index :orders, :payment_status unless index_exists?(:orders, :payment_status)
    add_index :orders, :paid_at unless index_exists?(:orders, :paid_at)
  end
end
