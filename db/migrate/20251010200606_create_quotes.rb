class CreateQuotes < ActiveRecord::Migration[7.2]
  def change
    create_table :quotes do |t|
      t.bigint :user_id, null: false
      t.bigint :created_by_id, null: false
      t.string :quote_number, null: false
      t.integer :status, default: 0, null: false
      t.date :valid_until, null: false
      t.text :notes
      t.integer :subtotal_cents, default: 0, null: false
      t.integer :tax_cents, default: 0, null: false
      t.integer :shipping_cents, default: 0, null: false
      t.integer :total_cents, default: 0, null: false
      t.string :currency, default: 'USD', null: false

      t.timestamps
    end
    
    add_index :quotes, :user_id
    add_index :quotes, :created_by_id
    add_index :quotes, :quote_number, unique: true
    add_index :quotes, :status
    add_foreign_key :quotes, :users, column: :user_id
    add_foreign_key :quotes, :users, column: :created_by_id
  end
end
