class CreateDealerBalances < ActiveRecord::Migration[7.2]
  def change
    create_table :dealer_balances do |t|
      t.references :dealer, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      t.integer :balance_cents, null: false, default: 0
      t.string :currency, default: 'USD', null: false
      t.integer :credit_limit_cents, default: 0
      t.datetime :last_transaction_at

      t.timestamps
    end
  end
end
