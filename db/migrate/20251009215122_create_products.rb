class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.integer :price_cents
      t.string :currency

      t.timestamps
    end
  end
end
