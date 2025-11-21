class AddTaxCentsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :tax_cents, :integer, default: 0, null: false
  end
end
