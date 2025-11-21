class UpdateProductsSchema < ActiveRecord::Migration[7.2]
  def change
    # Rename name to title
    rename_column :products, :name, :title
    
    # Add new columns
    add_column :products, :sku, :string
    add_column :products, :active, :boolean, default: true
    add_reference :products, :category, foreign_key: true
    
    # Add indexes
    add_index :products, :sku, unique: true
    add_index :products, :active
  end
end
