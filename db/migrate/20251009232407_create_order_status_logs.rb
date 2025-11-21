class CreateOrderStatusLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :order_status_logs do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status, null: false
      t.datetime :changed_at, null: false

      t.timestamps
    end
    
    add_index :order_status_logs, [:order_id, :changed_at]
  end
end
