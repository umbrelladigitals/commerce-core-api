class CreateProductOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :product_options do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :option_type, null: false, default: 'select'
      t.boolean :required, null: false, default: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :product_options, [:product_id, :name], unique: true
    add_index :product_options, [:product_id, :position]
  end
end
