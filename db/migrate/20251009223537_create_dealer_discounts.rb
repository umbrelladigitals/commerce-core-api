class CreateDealerDiscounts < ActiveRecord::Migration[7.2]
  def change
    create_table :dealer_discounts do |t|
      t.references :dealer, null: false, foreign_key: { to_table: :users }
      t.references :product, null: false, foreign_key: true
      t.decimal :discount_percent, precision: 5, scale: 2, null: false, default: 0.0
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :dealer_discounts, [:dealer_id, :product_id], unique: true
  end
end
