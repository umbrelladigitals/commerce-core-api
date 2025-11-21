class CreateVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku, null: false
      t.jsonb :options, default: {}
      t.integer :price_cents, null: false
      t.integer :stock, default: 0
      t.string :currency, default: 'USD'

      t.timestamps
    end

    add_index :variants, :sku, unique: true
    add_index :variants, :options, using: :gin
  end
end
