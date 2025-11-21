class AddDiscountToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :discount_cents, :integer, default: 0, null: false
    add_index :orders, :discount_cents
  end
end
