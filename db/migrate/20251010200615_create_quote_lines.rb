class CreateQuoteLines < ActiveRecord::Migration[7.2]
  def change
    create_table :quote_lines do |t|
      t.bigint :quote_id, null: false
      t.bigint :product_id, null: false
      t.bigint :variant_id
      t.string :product_title, null: false
      t.string :variant_name
      t.integer :quantity, default: 1, null: false
      t.integer :unit_price_cents, default: 0, null: false
      t.integer :total_cents, default: 0, null: false
      t.text :note

      t.timestamps
    end
    
    add_index :quote_lines, :quote_id
    add_index :quote_lines, :product_id
    add_index :quote_lines, :variant_id
    add_foreign_key :quote_lines, :quotes
    add_foreign_key :quote_lines, :products, column: :product_id
    add_foreign_key :quote_lines, :variants, column: :variant_id
  end
end
