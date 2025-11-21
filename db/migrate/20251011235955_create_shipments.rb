class CreateShipments < ActiveRecord::Migration[7.2]
  def change
    create_table :shipments do |t|
      t.bigint :order_id, null: false
      t.string :tracking_number, null: false
      t.string :carrier, null: false
      t.integer :status, default: 0, null: false
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.date :estimated_delivery
      t.text :notes

      t.timestamps
    end
    
    add_index :shipments, :order_id
    add_index :shipments, :tracking_number, unique: true
    add_index :shipments, :status
    add_index :shipments, :carrier
    add_foreign_key :shipments, :orders
  end
end
