class AddTaxToOrderLines < ActiveRecord::Migration[7.2]
  def change
    add_column :order_lines, :tax_rate, :decimal, precision: 5, scale: 4, default: 0.20
    add_column :order_lines, :tax_cents, :integer, default: 0
  end
end
