class AllowNullUserIdInOrders < ActiveRecord::Migration[7.2]
  def change
    # Allow NULL user_id for guest checkout orders
    change_column_null :orders, :user_id, true
  end
end
