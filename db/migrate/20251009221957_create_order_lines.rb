class CreateOrderLines < ActiveRecord::Migration[7.2]
  def change
    create_table :order_lines do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :variant, null: true, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :total_cents, null: false
      t.text :note

      t.timestamps
    end

    add_index :order_lines, [:order_id, :product_id, :variant_id]
  end
end
