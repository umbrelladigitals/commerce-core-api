class CreatePromotionsCoupons < ActiveRecord::Migration[7.2]
  def change
    create_table :promotions_coupons do |t|
      t.string :code
      t.integer :discount_type
      t.decimal :value
      t.integer :min_order_amount_cents
      t.string :min_order_amount_currency
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active
      t.integer :usage_limit
      t.integer :usage_count

      t.timestamps
    end
    add_index :promotions_coupons, :code
  end
end
