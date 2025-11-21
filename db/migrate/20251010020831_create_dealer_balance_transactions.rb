class CreateDealerBalanceTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :dealer_balance_transactions do |t|
      t.references :dealer_balance, null: false, foreign_key: true
      t.string :transaction_type, null: false  # credit, debit, topup, order_payment
      t.integer :amount_cents, null: false, default: 0
      t.text :note
      t.references :order, null: true, foreign_key: true  # İlişkili sipariş varsa

      t.timestamps
    end
    
    add_index :dealer_balance_transactions, :transaction_type
    add_index :dealer_balance_transactions, :created_at
  end
end
