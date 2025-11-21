class AddProductionStatusToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :production_status, :string, default: 'pending'
    add_index :orders, :production_status
  end
end
