class AddPropertiesToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :properties, :jsonb, default: {}
    add_index :products, :properties, using: :gin
  end
end
