class AddCreatedByMarketerToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :created_by_marketer_id, :integer
    add_index :orders, :created_by_marketer_id
  end
end
