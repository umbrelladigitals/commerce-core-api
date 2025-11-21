class CreateProductOptionValues < ActiveRecord::Migration[7.2]
  def change
    create_table :product_option_values do |t|
      t.references :product_option, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :price_mode, null: false, default: 'flat'
      t.integer :position, default: 0
      t.jsonb :meta, default: {}

      t.timestamps
    end

    add_index :product_option_values, [:product_option_id, :name], unique: true
    add_index :product_option_values, [:product_option_id, :position]
  end
end
