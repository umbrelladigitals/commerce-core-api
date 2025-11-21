class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.integer :total_cents
      t.string :currency

      t.timestamps
    end
  end
end
