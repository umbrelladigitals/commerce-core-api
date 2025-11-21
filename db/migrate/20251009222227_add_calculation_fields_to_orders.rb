class AddCalculationFieldsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :subtotal_cents, :integer, default: 0, null: false
    add_column :orders, :shipping_cents, :integer, default: 0, null: false
    add_column :orders, :paid_at, :datetime
    add_column :orders, :shipped_at, :datetime
    add_column :orders, :cancelled_at, :datetime
    
    add_index :orders, :paid_at
    add_index :orders, :shipped_at
  end
end
